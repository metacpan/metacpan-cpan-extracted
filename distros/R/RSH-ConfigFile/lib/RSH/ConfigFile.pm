# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

=head1 NAME

RSH::ConfigFile - Configuration File

=head1 SYNOPSIS

  use RSH::ConfigFile;

  my $config = new RSH::ConfigFile filename => 'foo.config';
  $config->load();
  my $setting = $config->{setting};
  $config->{setting} = 'new value';
  $config->save();

=head1 ABSTRACT

  RSH::ConfigFile is a configuration file that uses standard text
  'key = value' lines, where value can be a string, an array, or
  a hash.

=head1 DESCRIPTION

While using XML and YAML are both possible solutions
for a config file syntax, both suffer from having very specific syntax, 
punctuation, or whitespace requirements.  This module seeks to
use a simple, more robust config file syntax.  In addition to
having simple "key = value" syntax, values can also be more
complex structures.

This format is not a replacement for XML, YAML, or dump formats.
It seeks to be simple and readable while providing the ability to
specify slightly more complicated values then just plain strings.

=cut

package RSH::ConfigFile;

use 5.008;
use strict;
use warnings;

use overload 
  '""'  => \&string,
  '%{}' => \&get_hash;


use FileHandle;
use File::Copy "cp";
use Digest::MD5;
use RSH::Exception;
use RSH::SmartHash;
use RSH::LockFile;
use RSH::FileUtil qw(get_filehandle);

require Exporter;

=head2 EXPORT

None by default.

=cut

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
	
);

our $VERSION = '1.0.10';

# ******************** PUBLIC Class Methods ********************

=head2 CLASS METHODS

=over

=cut

=item serialize_value()

Converts the value into a string.

=cut

sub serialize_value {
	my %args = @_;

	my $value = $args{value};
	if (not defined($value)) { $value = ''; }

	if (not defined($args{no_quotes})) { $args{no_quotes} = 0; }
	else { $args{no_quotes} = $args{no_quotes} && 1; }

	# If it is an array reference
	if (ref($value) eq 'ARRAY') {
		my @contents = @{$value};
		for (my $i = 0; $i < scalar(@contents); $i++) {
			if ( (not $args{no_quotes}) && ($contents[$i] !~ m/^'.*'$/) ) { $contents[$i] = "'". $contents[$i] ."'"; }
		}
		my $str = "[ ";
		$str .= join ", ", @contents;
		$str .= " ]";
		return $str;
	}
	# If it is a hash reference
	elsif (ref($value) eq 'HASH') {
		my @contents;
		my $val;
		foreach my $key (sort keys %{$value}) {
			$val = $value->{$key};
			if ( (not $args{no_quotes}) && ($val !~ m/^'.*'$/) ) { $val = "'". $val ."'"; }
			push @contents, "$key => $val";
		}
		my $str = "{ ";
		$str .= join ", ", @contents;
		$str .= " }";
		return $str;
	}
	# Otherwise it is just a scalar/string
	else {
		if ( (not $args{no_quotes}) && ($value !~ m/^'.*'$/) ) { $value = "'". $value ."'"; }
		return $value;
	}
}

=item unserialize_value()

Tries to unserialize a string into a value.

=cut

sub unserialize_value {
	my $str = shift;

#	print STDERR "# RSH::ConfigFile::unserialize_value(): \$str == [[$str]]\n";
	my $val = undef;
	# Is it an array?
	if ($str =~ m/^\[(.*)\]$/) {
#		print STDERR "# RSH::ConfigFile::unserialize_value(): ARRAY value match\n";
		$val = [];
		my $str = $1;
		$str =~ s/\\,/\\;/;
		my @contents = split /,/, $str;
   		for (my $i = 0; $i < scalar(@contents); $i++) {
			$contents[$i] =~ s/\\;/,/;
			if ($contents[$i] =~ m/^\s*'?(.*?)'?\s*$/) { $contents[$i] = $1; }
		}
		return \@contents;
	}
	# Is it a hash?
	elsif ($str =~ m/^\{(.*)\}$/) {
#		print STDERR "# RSH::ConfigFile::unserialize_value(): HASH value match\n";
		$val = {};
		my $str = $1;
		$str =~ s/\\,/\\;/;
		my @contents = split /,/, $str;
		my ($key, $val);
		my %content_hash;
		for (my $i = 0; $i < scalar(@contents); $i++) {
			$contents[$i] =~ s/\\;/,/;
			($key, $val) = split /=>/, $contents[$i];
			if (defined($key) && ($key =~ m/^\s*'?(.*?)'?\s*$/)) { $key = $1; }
			if (defined($val) && ($val =~ m/^\s*'?(.*?)'?\s*$/)) { $val = $1; }
			# Only act on defined key values for hash
			if (defined($key)) { $content_hash{$key} = $val; }
		}
		return \%content_hash;
	}
	# Otherwise, treat it as a string
	else {
#		print STDERR "# RSH::ConfigFile::unserialize_value(): default to STRING value match\n";
		$val = $str;
		if ($val =~ m/^\s*'(.*?)'\s*$/) { $val = $1; }
		# Otherwise we just assume it is a string without quotes
		return $val;
	}
}

=item load_config()

Factory method; takes a filename, creates a config object, and loads from the file, returning
the freshly loaded config object.

=cut

sub load_config {
	my $filename = shift;

	my $config = RSH::ConfigFile->new($filename);
	my $success = $config->load();
	if ($success) { return $config; }
	if (not $success) { die "Error loading config for file \"$filename\". ERROR: ". $config->error(); }
}

=back

=cut

# ******************** Constructor Methods ********************

=head2 CONSTRUCTORS

=over

=cut

=item new(%ARGS)

Creates a new RSH::ConfigFile object.  C<%ARGS> contains
arguments to use in initializing the new instance.

Params:

  filename => filename to load from
  default  => reference to a hash to use for default values 
            (will not be saved to file)
  values   => reference to a hash to use for values

B<Returns:> A new RSH::ConfigFile object.

=cut

sub new {
	my $class = shift;
	my %params = @_;
	my $filename = $params{filename};
	my $default_ref = $params{default};
	my $hash_ref = $params{values};

	if (not defined($default_ref)) { $default_ref = {}; }
	if (not defined($hash_ref)) { $hash_ref = {}; }

	my $dirty = 0;
	if (%{$hash_ref}) { $dirty = 1; }

	tie my %hash, 'RSH::SmartHash', default => $default_ref, values => $hash_ref, dirty => 1;
	
	my $self = {};
	$self->{filename} = $filename;
	$self->{hash} = \%hash;
	$self->{error} = undef;
	$self->{warning} = undef;
	$self->{file_md5} = undef;
	if (defined($params{no_follow}) && ($params{no_follow} eq '1')) {
		$self->{no_follow} = 1;
	} else {
		$self->{no_follow} = 0;
	}
	if (defined($params{no_quotes}) && ($params{no_quotes} eq '1')) {
		$self->{no_quotes} = 1;
	} else {
		$self->{no_quotes} = 0;
	}
	if (defined($params{compact}) && ($params{compact} eq '1')) {
		$self->{compact} = 1;
	} else {
		$self->{compact} = 0;
	}

	bless $self, $class;
	
	return $self;
}

=back

=cut

# ******************** PUBLIC Instance Methods ********************

=head2 INSTANCE METHODS

=cut

# ******************** Accessor Methods ********************

=head3 Accessors

=over

=cut


=item is_dirty()

Read-only accessor for the object's dirty flag.  The dirty flag is set
whenever a value is changed for the object's hash values.

=cut

sub is_dirty {
	my $self = shift;

	return tied(%{$self->get_hash})->is_dirty();
}

=item filename()

Read-write accessor for filename attribute

=cut

sub filename {
	my $self = shift;
	my $val = shift;

	if (defined($val)) { 
		my $old_val = $self->get_hash_val('filename');
		$self->set_hash_val('filename', $val); 
		if ( (defined($old_val)) and ($old_val ne $val) ) {
			$self->set_hash_val('file_md5', undef);
			tied(%{$self->get_hash})->dirty(1);
		}
	}
	
	return $self->get_hash_val('filename');
}

=item error()

Read-only accessor for error attribute.  Error is set when an error occurs on
save or load.  If a load or save returns false for success, you can check this
attribute for the reason why.

=cut

sub error {
	my $self = shift;
	
	return $self->get_hash_val('error');
}

=item warning()

Read-only accessor for warning attribute.  Warning is set when an warning occurs on
save or load.  If a load or save returns false for success, you can check this
attribute for the reason why.

=cut

sub warning {
	my $self = shift;
	
	return $self->get_hash_val('warning');
}

=item md5()

Read-only accessor for md5 attribute.

=cut 

sub md5 {
	my $self = shift;
	
	return $self->get_hash_val('file_md5');
}

=item no_follow()

Read-only accessor for no_follow attribute.

=cut 

sub no_follow {
	my $self = shift;
	my $val = shift;

	if (defined($val)) {
		$self->{no_follow} = ($val && 1);
	}

	return $self->{no_follow};
}

=item no_quotes()

Read-only accessor for no_quotes attribute.

=cut 

sub no_quotes {
	my $self = shift;
	my $val = shift;

	if (defined($val)) {
		$self->{no_quotes} = ($val && 1);
	}

	return $self->{no_quotes};
}

=item compact()

Read-only accessor for compact attribute.

=cut 

sub compact {
	my $self = shift;
	my $val = shift;

	if (defined($val)) {
		$self->{compact} = ($val && 1);
	}

	return $self->{compact};
}

=back

=cut

# ******************** Functionality ********************

=head3 Functionality

=over

=cut

# ******************** Serialization ********************

=item load()

Loads the configuration object from a filename.

Params:

  filename => (optional) the file to load from

returns: 1 on success, 0 on failure, with exceptions for exceptionally bad errors

=cut

sub load {
	my $self = shift;
	my %params = @_;
	my $filename = $params{filename};

	$self->set_hash_val('error', undef);
	$self->set_hash_val('warning', undef);

	if (not defined($params{force})) { $params{force} = 0; }
	if (not defined($params{no_follow})) { $params{no_follow} = $self->{no_follow}; }

	if (not defined($filename)) { $filename = $self->get_hash_val('filename'); }
	if (not defined($filename)) { 
		die new RSH::CodeException message => "Filename is not defined for this config object." 
	}

	if (not -e $filename) { 
		die new RSH::FileNotFoundException message => "File \"$filename\" does not exist."; 
	}

	my $md5 = new Digest::MD5;
	eval {
		my $FILE = get_filehandle($filename, 'READ', no_follow => $params{no_follow});
		tied(%{$self->get_hash})->CLEAR();
#		$self->set_hash_val('hash', {});  # reinitialize values--do we want this?
		
		my $key = "";
		my $value = "";
		while (<$FILE>) {
			$md5->add($_);  # add, as is, first, so our md5 jibes with the real contents of the file
			s/(.*)\r\n$/$1\n/; # we hatesez the Windowsez!  Hates it we do!!  This happens in w2k3 server
			                   # and w2k server perl installations when they get confused about file modes
#			s/(.*)\r$/$1\n/; # Same thing might happen on a Mac, but I doubt it :-)
			if ((! m/^\s*#.*/) && (m/(\S*)\s*=\s*(\S*)/)) {
				# suck up next line while current line ends in "\"
				while (m/^.*\\\s*$/) { 
					my $temp = <$FILE>;    # grab the next line
					if (defined($temp)) {
						$md5->add($temp);
						if ($temp !~ m/^\s*#.*/) {
							s/^(.*)\\\s*$/$1/; # trim off the  trailing \
							$_ .= $temp;
						}
					} else {
						s/^(.*)\\\s*$/$1/; # trim off the  trailing \
						last; # get out of the loop
					}
				}
				($key, $value) = (m/(\S*)\s*=\s*(\S*.*)/);
				if (defined($key)) {
					$self->{$key} = unserialize_value($value);
				}
			}
		}
		close $FILE;
		my $digest = $md5->hexdigest;
		#print "# ConfigFile::load(): new md5 for load == $digest\n";
		$self->set_hash_val('file_md5', $digest);
	};
	if ($@) {
		$self->set_hash_val('error', $@);
		return 0;
	}

	tied(%{$self->get_hash})->dirty(0);
	return 1;
}

=item save()

Saves the values in this config object to the file.  If the file exists, formatting will be
preserved, with new values being added at the end.

Params:
  filename - (optional) the file to save to
  force - (optional) 1, force save, 0, rely on dirty flag; method assumes force => 0

returns: 1 on success, 0 on failure, with exceptions for exceptionally bad errors

=cut

sub save {
	my $self = shift;
	my %params = @_;
	my $filename = $params{filename};

	$self->set_hash_val('error', undef);
	$self->set_hash_val('warning', undef);

	if (not defined($params{force})) { $params{force} = 0; }
	if (not defined($params{no_follow})) { $params{no_follow} = $self->{no_follow}; }
	if (not defined($params{no_quotes})) { $params{no_quotes} = $self->{no_quotes}; }
	if (not defined($params{compact})) { $params{compact} = $self->{compact}; }

	# If a filename is supplied and it is NOT equal to the filename attribute, assume "always save"
	if ( (defined($filename)) && ($filename ne $self->get_hash_val('filename')) ) { $params{force} = 1; }

	# If not dirty and we are not forcing a save, stop processing and return success.
	if ((not $self->is_dirty) && (not $params{force}) ) { return 1; }

	if (not defined($filename)) { $filename = $self->get_hash_val('filename'); }
	if (not defined($filename)) { 
		die new RSH::CodeException message => "Filename is not defined for this config object.";
	}

	if (not -e $filename) {
		if (defined($self->get_hash_val('file_md5'))) {
			my $ex = new RSH::DataIntegrityException message => "Loaded from file, but saving to empty file.";
			if (not $params{force}) { die $ex; }
			else { $self->set_hash_val('warning', $ex); }
		}
		# if file does not exist, don't worry about any formatting
		eval {
			my $lock = RSH::LockFile->new($filename);
			$lock->lock(no_follow => $params{no_follow});

			my $FILE = get_filehandle("$filename", 'WRITE', no_follow => $params{no_follow});
			my $key = "";
			my $value = "";
			foreach $key (sort keys %{$self->get_hash}) {
				$value = $self->{$key};
				if (not defined($value)) { $value = ""; }  # ensures no errors and proper write to file;
			                                           	   # effectively the same thing to write a null string
				else { $value = serialize_value(value => $value, no_quotes => $params{no_quotes}); }
				if (not $params{compact}) {
					print $FILE "$key = $value\n";
				} else {
					print $FILE "$key=$value\n";
				}							
			}
			close $FILE;

			my $fh = new FileHandle "<$filename";
			my $md5 = new Digest::MD5;
			$md5->addfile($fh);
			$fh->close();;
			my $digest = $md5->hexdigest;
			#print "# ConfigFile::save()[new file]: new md5 for save == $digest\n";
			$self->set_hash_val('file_md5', $digest);
			$lock->unlock();
		};
		if ($@) {
			$self->set_hash_val('error', $@);
			return 0;
		}
	} else {
		# if file does exist, we need to worry about formatting
		if (not defined($self->get_hash_val('file_md5'))) {
			my $ex = new RSH::DataIntegrityException message => "In-memory data was not loaded from file.";
			if (not $params{force}) { die $ex; }
			else { $self->set_hash_val('warning', $ex); }
		}
		eval {
			my $lock = RSH::LockFile->new($filename);
			$lock->lock(no_follow => $params{no_follow});
# 			my $rc = system("mv $filename $filename.bak");
#			if ($rc != 0) { die new RSH::DataIntegrityException message => "Unable to backup original file!"; }
			my $rc = cp($filename, "$filename.bak");
			if ($rc == 0) { die new RSH::DataIntegrityException message => "Unable to backup original file!"; }
			$rc = unlink($filename);
			if ($rc == 0) { 
				die new RSH::DataIntegrityException 
				  message => "Unable to remove original file after backup!"; 
			}
			
			my $ORIG_FILE = get_filehandle("$filename.bak", 'READ', no_follow => $params{no_follow});
			my $md5 = new Digest::MD5;
			$md5->addfile($ORIG_FILE);
			$ORIG_FILE->close;
			my $orig_md5 = $md5->hexdigest;
			if ( defined($self->get_hash_val('file_md5')) and ($self->get_hash_val('file_md5') ne $orig_md5) ) {
				my $ex = new RSH::DataIntegrityException message => "Data file has changed since the last load.";
				if (not $params{force}) { die $ex; }
				else { $self->set_hash_val('warning', $ex); }
			}

			$ORIG_FILE = get_filehandle("$filename.bak", 'READ', no_follow => $params{no_follow});
			my $FILE = get_filehandle("$filename", 'WRITE', no_follow => $params{no_follow});

			my $key = "";
			my $value = "";
			my @saved;
			while (<$ORIG_FILE>) {
				if ((! m/^\s*#.*/) && (m/(\S*)\s*=\s*(\S*)/)) {
					# suck up next line while current line ends in "\"
					while (m/^.*\\\s*$/) { 
						my $temp = <$ORIG_FILE>;    # grab the next line
						if (defined($temp) && ($temp !~ m/^\s*#.*/)) {
							s/^(.*)\\\s*$/$1/; # trim off the  trailing \
							$_ .= $temp;
						} elsif (not defined($temp)) {
							s/^(.*)\\\s*$/$1/; # trim off the  trailing \
							last; # get out of the loop
						}
					}
					($key, $value) = (m/(\S*)\s*=\s*(\S*.*)/);
					if ( (defined($key)) && (defined($self->{$key})) ) {
						$value = $self->{$key};
						if (not defined($value)) { $value = ""; }  # ensures no errors and proper write to file;
						                                           # effectively the same thing to write a null string
						else { $value = serialize_value(value => $value, no_quotes => $params{no_quotes}); }
						if (not $params{compact}) {
							print $FILE "$key = $value\n";
						} else {
							print $FILE "$key=$value\n";
						}							
						push @saved, $key;
					}
				} else {
					print $FILE $_;
				}
			}
			
			close $ORIG_FILE;

			my @keys = sort keys %{$self};
			if (scalar(@saved) < scalar(@keys)) {
				for (my $i = 0; $i < scalar(@keys); $i++) {
					if (grep(/$keys[$i]/, @saved) == 0) {
						$value = $self->{$keys[$i]};
						if (not defined($value)) { $value = ""; }  # ensures no errors and proper write to file;
						                                           # effectively the same thing to write a null string
						else { $value = serialize_value(value => $value, no_quotes => $params{no_quotes}); }
						if (not $params{compact}) {
							print $FILE "$keys[$i] = $value\n";
						} else {
							print $FILE "$keys[$i]=$value\n";
						}							
					}
				}
			}
			close $FILE;

			$FILE = get_filehandle("$filename", 'READ', no_follow => $params{no_follow});
			$md5->new;
			$md5->addfile($FILE);
			$FILE->close();
			my $digest = $md5->hexdigest;
			#print "# ConfigFile::save()[existing file]: new md5 for save == $digest\n";
			$self->set_hash_val('file_md5', $digest);
			$lock->unlock();
		};
		if ($@) { 
			$self->set_hash_val('error', $@);
			return 0;
		}
	}		

	tied(%{$self->get_hash})->dirty(0);
	return 1;
}

=item remove()

Removes the config file.

=cut 

sub remove {
	my $self = shift;
	my %params = @_;
	my $filename = $params{filename};

	if (not defined($filename)) { $filename = $self->get_hash_val('filename'); }
	if (not defined($filename)) { die new RSH::CodeException message => "Filename is not defined for this config object." }

	if (not -e $filename) { return 1; }
	else {
		my $rc = unlink("$filename");
		if ($rc == 0) { die new RSH::DataIntegrityException message => "Unable to remove file $filename."; }
		$self->set_hash_val('file_md5', undef);
		return 1;
	}
}

# ******************** Overload Methods ********************

=item string()

Returns a string representation of the object.  This is useful for debugging.  It is NOT
suitable to be used for serializing the object.  Use save for that.

=cut

sub string {
	my $self = shift;

	my $str = "{ ";
	my $key = "";
	my $value = "";
	foreach $key (sort keys %{$self->get_hash()}) {
		$value = $self->{$key};
		if (not defined($value)) { $value = "undef"; }  # could be confusing if that is the real value ;-)
		else { $value = serialize_value(value => $value); }
		# if this is not the first pair
		if ($str ne "{ ") { $str .= ", " }
		$str .= "$key => $value";
	}
	$str .= " }";
	return $str;
}

=item get_hash()

Returns the 'hash' hash reference.

Ok, this is a bit confusing if you haven't read the overload manpage, and still
confusing if you haven't tried it ;-)

The overload maps all attempts to use this object reference as a hash to this method.
So, $config->{key} will actually call this method--and what this method does is return the
hash table reference in 'hash'.  So, a quick step by step is as follows:

$config->{key} ==> get_hash($config) ==> (returns 'hash') ==> ('hash')->{key}

So this method returns the hash, which is in turn accessed for the key 'key'.  Neat and
confusing, no?

=cut

sub get_hash {
	my $self = shift;

	return $self->get_hash_val("hash");
}

# ******************** "PRIVATE" Instance Methods ********************

=begin private

=item get_hash_val()

Gets past the overload so we can actually get at the $self hash values.  All attempts
at $self->{key} will actually call get_hash(), so we need a way around that to
get at the values of self.

Thank you overload manpage!

=cut

sub get_hash_val {
	my $self = shift;
	my $key = shift;
	my $class = ref $self;
	bless $self, 'overload::dummy'; # Disable overloading of %{}
	my $val = $self->{$key};
	bless $self, $class;        # Restore overloading
	$val;
}

=item set_hash_val()

Gets past the overload so we can actually set the $self hash values.

Thank you overload manpage!

=cut

sub set_hash_val {
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $class = ref $self;
	bless $self, 'overload::dummy'; # Disable overloading of %{}
	$self->{$key} = $val;
	bless $self, $class;        # Restore overloading
	$val;
}

=end private

=back

=cut

# #################### RSH::ConfigFile.pm ENDS ####################
1;

=head1 SEE ALSO

http://www.rshtech.com/software/

=head1 AUTHOR

Matt Luker  C<< <mluker@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Matt Luker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

__END__
# TTGOG

# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.14  2004/04/09 06:18:26  kostya
#  Added quote escaping capabilities.
#
#  Revision 1.13  2004/01/15 01:07:17  kostya
#  New version for changes in tests.
#
#  Revision 1.12  2003/12/27 07:46:12  kostya
#  Fix for an empty element in a hash--i.e. if the last element has a comma after it, generating a null pair
#
#  Revision 1.11  2003/12/27 07:42:07  kostya
#  Fix for slash-continues and comments
#
#  Revision 1.10  2003/11/14 05:30:17  kostya
#  Bumped rev.
#
#  Revision 1.9  2003/10/23 05:13:32  kostya
#  Added some explaination for s// in load.
#
#  Revision 1.8  2003/10/23 05:08:06  kostya
#  Bumped rev.
#
#  Revision 1.7  2003/10/23 05:06:17  kostya
#  Added a check for brain-dead Windows perl installations.
#
#  Revision 1.6  2003/10/22 20:56:10  kostya
#  Bumped rev.
#
#  Revision 1.5  2003/10/22 20:51:02  kostya
#  Removed OS-specifc assumptions or code
#
#  Revision 1.4  2003/10/15 01:08:12  kostya
#  Bumped rev for getting licenses in order.
#
#  Revision 1.3  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.2  2003/10/14 22:50:07  kostya
#  Bumped release
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
#  Revision 1.7  2003/08/30 06:39:05  kostya
#  Patched undefined key in hash values.
#
#  Revision 1.6  2003/08/23 07:13:28  kostya
#  Added md5 checksums.
#
#  Revision 1.5  2003/08/23 01:02:32  kostya
#  Added remove and changed to SmartHash.
#
#  Revision 1.4  2003/08/06 03:31:26  kostya
#  Change callback and dirty flag work.
#
#  Revision 1.3  2003/08/01 00:52:50  kostya
#  Latest infrastructure work.
#
#  Revision 1.2  2003/07/30 06:30:49  kostya
#  Added comments and file-locking.
#
#  Revision 1.1.1.1  2003/07/25 07:06:35  kostya
#  Initial Import
#
# ------------------------------------------------------------------------------

