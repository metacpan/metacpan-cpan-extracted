package Net::NISplusTied;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Net::NISplusTied macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Net::NISplusTied $VERSION;

# Preloaded methods go here.

#############################################################
sub stringify {

	my ($self, $x) = @_;	
	my $q = '[';
	$q .= $x unless ref $x;	# assume string

	if (ref $x eq 'HASH') {
		for (keys %$x) {
			$q .= $_.'='. $x -> {$_} . ',';
		}
	}

	return $q . '],' . $self -> {'__nishash_name'};

}
#############################################################
sub TIEHASH {

	my $self = shift;
	my $data = {};

	$data -> {'__nishash_name'} = shift;
	$data -> {'__nishash_multiple'} = shift;

        my $class = ref ($self) || $self;

	return bless $data, $class;

}
#############################################################
sub FETCH {

	my ($self, $keyx) = @_;
	my $q;

	return $self->{$keyx} if $keyx =~ /^__nishash_/;
	$q = stringify ($self, $keyx);

	my $r = nismatch ($q, $self -> {'__nishash_name'});

	return $r;

}
#############################################################
sub STORE {
	
	my ($self, $key, $value) = @_;
        my %keyhash = %$value;		# we need a local copy
	my $q;

	$q = stringify ($self, $key);

	@_ = split /,/, $key;		# query to []

	map {/([^=]+)=([^=]+)/; $keyhash {$1} = $2} @_;

	nismodify ($q, $self -> {'__nishash_name'}, \%keyhash);

}
#############################################################
sub DELETE {

	my ($self, $key) = @_;
        return delete $self -> {$key} if $key =~ /^__nishash_/;
	my $q;

	$q = stringify ($self, $key);

	nisremove ($q);

}
#############################################################
sub DESTROY {

	my ($self) = @_;
	undef $self;
	
}
#############################################################
sub EXISTS {

	my ($self, $keyx) = @_;
#	warn "EXISTS called with ", @_;

        my $q = stringify ($self, $keyx);
	my $r = nismatch ($q, $self -> {'__nishash_name'});

	scalar @$r;	# FALSE if no elements
}
#############################################################
sub FIRSTKEY {

	warn "FIRSTKEY called";
}
#############################################################

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::NISplusTied -- TIEHASH() interface to NIS+ tables

=head1 SYNOPSIS

	use Net::NISplusTied;
  
	tie (%hash, Net::NISplusTied, 'your.table.domain.');
 
	### lookups
	$arrayref = $hash {'field=key'};
	$arrayref = $hash {'field1=key1,field2=key2'};
	$arrayref = $hash {{field => $key}};
	$arrayref = $hash {{field1 => $key1, field2 => $key2}};

	$hashref = $hash {'field1=key'} [0];
	$value = $hash {'field1=key'} [0] {field2};
 
	### modify value
	$hash {'field1=key'} = {field2 => $newvalue2, field3 => $newvalue3};
	$hash {{field1 => $key}} = {field2 => $newvalue2, field3 => $newvalue3};
 
	### delete entry
	delete $hash {'field1=key'};
	delete $hash {{field => $key}};
 
	### iterate through table
	# not implemented #

=head1 DESCRIPTION

The B<Net::NISplusTied> allows you to treat NIS+ tables as if they were perl
hashes, using tie() semantics.  It has cultural links to Rick Harris
(Rik.Harris@fulcrum.com.au) NISperl module, although the design goals were
different.  All you can do with B<Net::NISplusTied> is to manipulate NIS+ tables. 
If you need faithful NIS+ API implementation, consider using NISperl
instead.  The assumption was that one would rarely need to create and delete
NIS+ tables and groups from perl, at least not often enough to be seriously
inconvenienced by C<system 'nistbladm' ...> etc.

=head2 tie()

The third argument to tie() is the fully qualified name of the
table you wish to tie.  The module disregards NIS_PATH settings.

=head2 FETCH()

Hash lookups should have NIS+ indexes as the keys, with no
square brackets.  The following are shell and perl eqivavlents:

I<shell:>

	nismatch [name=bob,age=33],users.my.domain.

I<perl:>

	tie (%users, Net::NISplusTied, 'users.my.domain.');
	$results = $users {'name=bob,age=33'};

The value returned from a lookup is an array ref.  Array elements
are hash refs representing the individual entries.  Hashes are
keyed by the table columns.  The following would print user
bob's login shell setting from the stock passwd.org_dir file:

	tie (%passwd, Net::NISplusTied, 'passwd.org_dir.your.domain.');
	print $passwd {'name=bob'} [0] {shell};


=head2 STORE()

The STORE() method need some explanations.  It takes  scalar as a key and 
hash ref as a value. If the result of key lookup returns exactly B<one>
entry, this entry is replaced. If there is none or more than one, entry is
added to the table. It is up to you to ensure that the indexes stay unique,
since the module will not do this.  Consider the following table:

	field1		field2		field3
	---------------------------------------------
	apple		cat		...
	apple		dog		...
	orange		cat		...

	tie (%table, Net::NISplusTied, ...);

The following piece of code

	$table {'field1=apple,field2=cat'} = {field3 => 'whatever'};

will chnage entry [1], but

	$table {'field1=apple'} = {field2 => 'cat', field3 => 'whatever'};

will B<add> a new entry to the table, since field1=apple is not unique.


=head2 DELETE()

	delete $passwd {'name=bob'}

does what you think it does.  Be careful however, REM_MULTIPLE flag is
set, and running

	delete $passwd {''}

will remove ALL ENTRIES from the table.

=head2 DESTROY()

C<destroy $passwd;> frees up the memory taken by the hash.
You should not normally need this.
	

=head1 NOTE

Copyright (c) 1998 Ilya Ketris. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Ilya Ketris, ilya@gde.to

=head1 SEE ALSO

perl(1), perlguts(1), nis(1)

=cut
