package Mock::Data::Plugin::Text;
use Mock::Data::Plugin -exporter_setup => 1;
use Mock::Data::Charset;
use Mock::Data::Util 'coerce_generator';
use Scalar::Util 'blessed';
use Carp;
our @CARP_NOT= qw( Mock::Data Mock::Data::Util );

# ABSTRACT: Mock::Data plugin that provides text-related generators
our $VERSION = '0.04'; # VERSION


our $word_generator= Mock::Data::Charset->new(
	notation => 'a-z',
	str_len => sub { 1 + int(rand 3 + rand 3 + rand 4) }
);
*word= $word_generator->compile;

export(qw( word words lorem_ipsum join ));

sub apply_mockdata_plugin {
	my ($class, $mock)= @_;
	$mock->add_generators(
		'Text::join'        => \&join,
		'Text::word'        => $word_generator,
		'Text::words'       => \&words,
		'Text::lorem_ipsum' => \&lorem_ipsum,
	);
}


sub join {
	my $mockdata= shift;
	my $opts= @_ && ref $_[0] eq 'HASH'? shift : undef;
	my $sep= $_[0] // ($opts && $opts->{sep}) // ' ';
	my $source= $_[1] // ($opts && $opts->{source}) // Carp::croak("Parameter 'source' is required");
	my $count= $_[2] // ($opts && $opts->{count}) // 1;
	my $len= $opts? $opts->{len} : undef;
	my $max_len= $opts? $opts->{max_len} : undef;
	
	my @source_generators= map coerce_generator($_), ref $source eq 'ARRAY'? @$source : ( $source );
	my $buf= $source_generators[0]->generate($mockdata);
	my $src_i= 1;
	if (defined $len) {
		while (length($buf) < $len && (!defined $max_len or length($buf) + length($sep) < $max_len)) {
			$buf .= $sep . $source_generators[$src_i++ % scalar @source_generators]->generate($mockdata);
		}
	} else {
		my $lim= $count * scalar @source_generators;
		while ($src_i < $lim && (!defined $max_len or length($buf) + length($sep) < $max_len)) {
			$buf .= $sep . $source_generators[$src_i++ % scalar @source_generators]->generate($mockdata);
		}
	}
	substr($buf, $max_len)= ''
		if defined $max_len && length($buf) > $max_len;
	return $buf;
}


sub words {
	my $mockdata= shift;
	my %opts= @_ && ref $_[0] eq 'HASH'? %{ shift() } : ();
	if (@_) {
		@opts{'len','max_len'}= ref $_[0] eq 'ARRAY'? @{$_[0]} : @_[0,0];
	}
	$opts{source} //= $mockdata->generators->{word};

	$mockdata->call('join', \%opts);
}


my $lorem_ipsum_classic=
 "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor "
."incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis "
."nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.  "
."Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu "
."fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in "
."culpa qui officia deserunt mollit anim id est laborum.  ";

sub lorem_ipsum {
	my $mockdata= shift;
	my $len= @_ > 1? $_[1] : !ref $_[0]? $_[0] : ref $_[0] eq 'HASH'? $_[0]{len} : undef;
	return $lorem_ipsum_classic
		unless defined $len;
	my $ret= $lorem_ipsum_classic x int(1+($len/length $lorem_ipsum_classic));
	substr($ret, $len)= '';
	$ret =~ s/\s+$//;
	return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Plugin::Text - Mock::Data plugin that provides text-related generators

=head1 SYNOPSIS

  my $mockdata= Mock::Data->new(['Text']);
  
  # Strings of /(\w+ )+/
  $mockdata->words($len)            # up to $size characters
  
  # classic boilerplate
  $mockdata->lorem_ipsum($len)

  # Build strings of words
  $mockdata->join({ source => '{lorem_ipsum}', sep => '<p>', count => 5 });

=head1 DESCRIPTION

This plugin for L<Mock::Data> generates simple text patterns.  It may be expanded to support
multiple languages in the future.

=head1 GENERATORS

=head2 join

  $mockdata->join( $sep, $source, $count ); # concatenate strings from generators
  $mockdata->join( \%options );

This generator concatenates the output of other generators.  If the generators return arrays,
the elements will become part of the list to concatenate.  The generator can either concatenate
everything, or concatenate up to a size limit, calling the generators repeatedly until it
reaches the goal.

=over

=item sep

The separator; defaults to a space.

=item source

One or more generators.  They will be coerced to generators if they are not already.
If this is an arrayref, it will be considered as a list of generators and I<not> coerced into
a L<uniform_set|Mock::Data::Set/new_uniform>.

=item count

The number of times to call each generator.  This defaults to 1.

=item len

The string length goal.  The generators will be called repeatedly until this lenth is reached.

=item max_len

The string length maximum.  If the output is longer than this, it will be truncated, and the
final separator will be removed if the string would otherwise end with a separator.

=back

=head2 word

  $mockdata->word;

This generator returns one "word" which is roughly C<< /\w{1,11}/a >> but distributed more
heavily around 5 characters.

=head2 words

  $mockdata->words($max_len);

This is an alias for C<< ->join({ source => '{word}', len => $max_len, max_len => $max_len }) >>.
It takes the same named options as L</join>, but if a positional parameter is given, it
specifies C<$len> and C<$max_len>.

=head2 lorem_ipsum

  $mockdata->lorem_ipsum($len)
  $mockdata->lorem_ipsum({ len => $len })

Repetitions of the classic 1500's Lorem Ipsum text up to length C<len>

The default length is one iteration of the string.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.04

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
