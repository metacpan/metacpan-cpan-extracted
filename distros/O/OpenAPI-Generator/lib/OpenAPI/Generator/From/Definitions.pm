package OpenAPI::Generator::From::Definitions;

use strict;
use warnings;

use Carp qw(croak);
use File::Find;
use OpenAPI::Generator::Util qw(merge_definitions);

BEGIN {

  if (eval { require YAML::XS }) {
    YAML::XS->import('Load');
  }
  elsif (eval { require YAML }) {
    YAML->import('Load');
  }
  else {
    require CPAN::Meta::YAML;
    CPAN::Meta::YAML->import('Load');
  }

  if (eval { require JSON::XS }) {
    JSON::XS->import('decode_json')
  }
  else {
    require JSON::PP;
    JSON::PP->import('decode_json');
  }

}

sub new {

  bless {}, shift
}

sub generate {

  my($self, $conf) = @_;

  my $src = $conf->{src};
  $self->_check_src($src);
  my @files = $self->_src_as_files($src);

  if (!@files) {
    croak "no files found in $src";
  }

  my @defs = @{ $conf->{definitions} };

  for my $file (@files) {
    croak "$file is not readable" unless -r $file;

    local $/ = '';
    open my $fh, '<', $file or croak "can't open file $file";
    my $content = <$fh>;
    close $fh;


    if ($file =~ /\.json$/) {
      push @defs, decode_json($content);
    }
    else {
      push @defs, Load($content);
    }
  }

  merge_definitions(@defs)
}

sub _check_src {

  croak "$_[1] is not file or directory" unless(-f $_[1] or -d $_[1]);
  croak "$_[1] is not readable" unless(-r $_[1]);
}

sub _src_as_files {

  return $_[1] if -f $_[1];

  my @files;
  find sub { push @files, $File::Find::name if /\.(yml|yaml|json)$/ }, $_[1];
  @files
}

1

__END__

=head1 NAME

OpenAPI::Generator::From::Definitions - Generate openapi single definition from several definitions in yaml or json!

=head1 SYNOPSIS

You probably want to use it from OpenAPI::Generator's exported subroutine called 'openapi_from':

  use OpenAPI::Generator;

  my $openapi_def = openapi_from(definitions => {src => 'definitions/', definitions => @additional_definitions});

But also you can use it directly:

  use OpenAPI::Generator::From::Definitions;

  my $generator = OpenAPI::Generator::From::Definitions->new;
  my $openapi_def = $generator->generate({src => 'definitions/'})


=head1 METHODS

=over 4

=item new()

Creates new instance of class

  my $generator = OpenAPI::Generator::From::Definitions->new

=item generate($conf)

Using directory (will look for files ending with .json, .yaml or .yml)

  $generator->generate({src => 'definitions/'});


Using array of hashes (definitions)

  $generator->generate({definitions => @definitions});

Both options can be combined

=back

=head1 OPTIONS

=over 4

=item src

File path to file/directory of definitions to read from

=item definitions

Array of hashes, containing OpenAPI definitions

=back

=head1 AUTHOR

Anton Fedotov, C<< <tosha.fedotov.2000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<https://github.com/doojonio/OpenAPI-Generator/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc OpenAPI::Generator

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Anton Fedotov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)