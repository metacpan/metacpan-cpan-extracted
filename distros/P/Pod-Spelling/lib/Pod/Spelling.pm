use strict;
use warnings;
use utf8;

package Pod::Spelling;
our $VERSION = 0.6; # Catch undefined

use Pod::POM;
require Pod::POM::View::TextBasic;
use warnings::register;
use Carp;

sub new {
	my ($class, $args) = (
		(ref($_[0])? ref($_[0]) : shift ),
		(ref($_[0])? shift : {@_})
	);

	# Pod::POM->default_view( 'Pod::POM::View::TextBasic' )
	# 	or confess $Pod::POM::ERROR;

	my $self = bless {
		%$args,
		_parser => Pod::POM->new,
		_temp_stoplist => [],
	}, $class;
	
	$self->{skip_paths_matching} ||= [];

	$self->{view} ||= 'Pod::POM::View::TextBasic';

	# Allow a single word to be allowed:
	if ($self->{allow_words} and not ref $self->{allow_words}){
		$self->{allow_words} = [ $self->{allow_words} ];
	}

	unless ($self->{not_pod_wordlist}){
		eval { 
			no warnings;
			require Pod::Wordlist ;
		};
		warnings::warnif( $@ ) if $@;
	}
	
	if (ref $self and $self->{import_speller}){
		$self->import_speller( $self->{import_speller} );
	}

	# If no speller was specified and no callback provided,
	# try to find one of the defaults.	
	else {
		if (not $self->{spell_check_callback}){
			foreach my $mod (qw( Ispell Aspell )){
				last if $self->import_speller( 'Pod::Spelling::'.$mod );
			}
		}
		$self = $self->_init;
	}

	Carp::confess 'Could not instantiate any spell checker. Do you have Ispell or Aspell installed with dictionaries?'
		if not $self->{spell_check_callback};

	return $self;
}

# Abstract method to be implemented by sub-classes:
# if AOK, return calling object, otherwise error string.
sub _init { return $_[0] }

sub import_speller {
	my ($self, $class) = @_;

	eval "require $class";	

	if ($@){
		warnings::warnif($@);
		$self->{spell_check_callback} = undef;
		return undef;
	}
	else {
		my $method = $class.'::_init';
		$self = $self->$method;
		$self->{spell_check_callback} = $class."::_spell_check_callback"
			if ref $self;
	}
	
	return ref $self;
}

# Method that accepts one or more lines of text, returns a list mispelt words.
sub _spell_check_callback {
	my $self = shift;
	warnings::warnif( 
		'No spell_check_callback registered: no spell checking is happening!'
	);
	# Return all words as errors
	return split /\s+/, join "\n", @_;	
}


sub _clean_text {
	my ($self, $text) = @_;
	return '' if not $text;
	
	$text =~ s/(\w+::)+\w+/ /gs;	# Remove references to Perl modules
	$text =~ s/\s+/ /gs;
	$text =~ s/[()\@,;:"\/.]+/ /gs;		# Remove punctuation
	$text =~ s/\d+//sg;
	$text =~ s/["'](\w+)["']/$1/sg;
	$text =~ s/\b-(\w+)/ $1/sg;
	$text =~ s/(\w+)-\b/$1 /sg;
	
	foreach my $word ( @{$self->{allow_words}} ){
		next if not defined $word;
		$text =~ s/\b\Q$word\E\b//sig;
	}

	unless (exists $self->{no_pod_wordlist} or exists $self->{no_pod_wordlist}){
		no warnings 'once';
		foreach my $word (split /\s+/, $text){
			$word = '' if exists $Pod::Wordlist::Wordlist->{$word};
		}
	}

	# Allow words that are joined by underscores but
	# which were thought errors: easier than parsing
	# Perl, for now:
	$text =~ s/(\w+_\w+||_\w+||\w_)//sg;

	return $text;
}


# Returns all badly spelt from the file,
# and sets $self->{errors}->[ $line_number-1 ]->[ badly spelt words for this line ]
sub check_file {
	my ($self, $path) = @_;
    my ($packages, @rv);
    $self->{errors} = [];
	
	foreach my $re (@{ $self->{skip_paths_matching} }){
		return () if $path =~ $re;
	}

	# Crude test to allow package names:
	{
		# Hope it is not too large.
		open my $IN, $path or confess "$! - $path";
		read $IN, my $content, -s $IN;
		close $IN;

		my @packages = grep {length} $content =~ /^([}{;]+||)\s*package\s+([a-z](?:[\w]+||::)*?)\s*[;{]/img;

		$self->add_allow_words(
			@packages,				# Whole package names
			# Parts of package names
			map {
				split /::/, $_
			} @packages
		);
	}

	# To support '=for stopwords', we could create yet another parser, 
	# and reparse the document, but not sure why that would be better
	# than this:

		
    my $pom = $self->{_parser}->parse_file($path)
    	or confess $self->{_parser}->error();

	my $code = $self->{spell_check_callback};
	
	my $line = 0;
	foreach my $node ($pom->content){

		if ($node->type() =~ /^(begin|for)$/){
			my $allowed_line = $node->present( $self->{view} );
			my @stoplist = split /\s/, $allowed_line;
			$self->_add_temporary_stoplist( @stoplist );
			next;
		}

		my $text = $node->present( $self->{view} );
		$text =~ s/[\n\r\f]+/ /sg;

		$text = $self->_clean_text( $text );
		my @err = $self->$code( $text );
		
		ERR:
		foreach my $err (@err){
			foreach my $word (grep {length} split /\s+/, $text){
				if ($word =~ /([\d_-]\Q$err\E|\Q$err\E[\d_-])/sg){
					$err = undef;
					next ERR;
				}
			}
			# Check packages
			eval {
				require $path;
				foreach my $p (keys %$packages){
					eval { import $p };
					# die "$err is a method in $p"
					undef $err if $p->can( $err );
				}
			};
		}
		
		@err = grep {defined} @err;
		
		if (@err){
			push @rv, @err;
			$self->{errors}->[$line] = \@err;
		}
		$line ++;
	}

	$self->_remove_temporary_stoplist;

	return @rv;
}

sub add_allow_words {
	my $self = shift;
	push @{ $self->{allow_words} }, @_ if $#_ > -1;
}

sub skip_paths_matching {
	my $self = shift;
	push @{ $self->{skip_paths_matching} }, @_ if $#_ > -1;
	return @{ $self->{skip_paths_matching} };
}

sub _add_temporary_stoplist {
	my ($self, @stoplist) = @_;
	my $dict = { map {$_=>1} @{$self->{allow_words}} };
	my @new;
	foreach my $word (@stoplist){
		push @new, $word if not exists $dict->{$word};
	}
	push @{ $self->{_temp_stoplist} }, \@new;
	$self->add_allow_words( @new );
}

sub _remove_temporary_stoplist {
	my ($self, @stoplist) = @_;
	return if not scalar @{ $self->{_temp_stoplist} };
	my $remove = { map {$_=>1} pop @{ $self->{_temp_stoplist} } };
	my @allowed;
	foreach my $word (@{ $self->{allow_words} }){
		push @allowed, $word if not exists $remove->{$word};
	}
}

1;

=encoding utf8

=head1 NAME

Pod::Spelling - Send POD to a spelling checker

=head1 SYNOPSIS

	use Pod::Spelling;
	my $o = Pod::Spelling->new();
	say 'Spelling errors: ', join ', ', $o->check_file( 'Module.pm' );

	use Pod::Spelling;
	my $o = Pod::Spelling->new( import => 'My::Speller' );
	say 'Spelling errors: ', join ', ', $o->check_file( 'Module.pm' );

	use Pod::Spelling;
	my $o = Pod::Spelling->new(
		allow_words => [qw[ foo bar ]],
	);
	$o->skip_paths_matching( qr{*/DBIC} );
	say 'Spelling errors: ', join ', ', $o->check_file( 'Module.pm' );

=head1 DESCRIPTION

This module provides extensible spell-checking of POD.

At present, it requires either L<Lingua::Ispell> or L<Text::Aspell>,
one of which  must be installed on your system, with its binaries, 
unless you plan to use the API to provide your own spell-checker. In
the latter case, or if binaries are missing from their default locations,
expect test failures.

=head1 TEXT NOT SPELL-CHECKED

The items below commonly upset spell-checking, though are generally
considered valid in POD, and so are not sent to the spell-checker.

=over 4

=item *

The body of links (C<LE<lt>...E<gt>>) and file-formatted strings (C<FE<lt>...E<gt>>).

=item *

Verbatim blocks (indented text, as used in C<SYNOPSIS> sections.

=item *

Any string containing two colons (C<::>).

=item *

The name of the module as written in the standard POD manner:

	=head1 NAME
	
	Module::Name::Here - brief description here
	
=item *

Words contained in L<Pod::Wordlist|Pod::Wordlist>, though that can be disabled
- see the C<no_pod_wordlist>, below.

=back
	
=head1 CONSTRUCTOR (new)

Optional parameters:

=over 4

=item C<allow_words>

A list of words to remove from text prior to it being spell-checked.

=item C<no_pod_wordlist>

Prevents the default behaviour of using L<Pod::Wordlist|Pod::Wordlist> 
to ignore words often used in Perl modules, but rarely found in dictionaries.

=item C<import_speller>

Name of a class to that implements
the C<_init> method and the C<Pod::Spelling::_spell_check_callback> method.
Current implementations are L<Pod::Spelling::Ispell|Pod::Spelling::Ispell>
and L<Pod::Spelling::Aspell|Pod::Spelling::Aspell>. If anything else should be
added, please let me know.

=back

If no C<import_speller> is specified, then C<Ispell> is tried, then C<Aspell>,
then the module croaks.

=head1 DEPENDENCIES

L<Pod::POM|Pod::POM>.

=head1 METHODS

=head2 check_file

Accepts a path to a file, runs the spell check, and returns a list of badly-spelt
words, setting the C<errors> field with an array, each entry of which is a list that
represents a line in the file, and thus may be empty if there are no spelling errors.

=head2 add_allow_words

Add a list of words to the 'allow' list specified at instantiation.

=head2 skip_paths_matching

Supply a list of one or more pre-compiled regular expressions to
avoid parsing directories they match.

=head1 ADDING A SPELL-CHECKER

This module is really just a factory class that does nothing but 
provide an API for sending POD to a spelling checker via a callback method,
and returning the results. 

The spell-checking callback method, supplied as a
code reference in the C<spell_check_callback> argument during construction,
receives a list of text, and should return a list of badly-spelt words.

	my $o = Pod::Spelling->new(
		spell_check_callback => sub { 
			my ($self, @text) = @_;
			return $find_bad_words( \@text );
		},
	);

Alternatively, this module can be sub-classed: see the source of
C<Pod::Spelling::Ispell>.

=head1 SEE ALSO

L<Pod::Spelling::Ispell>,
L<Pod::POM>,
L<Pod::POM::View::TextBasic>,
L<Pod::Spell>,
L<Pod::WordList>.

=head1 AUTHOR AND COPYRIGHT

Copyright (C) Lee Goddard, 2011. All Rights Reserved.

Made available under the same terms as Perl.


