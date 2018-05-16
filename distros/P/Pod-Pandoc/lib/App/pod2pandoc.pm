package App::pod2pandoc;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.3.2';

use Getopt::Long qw(:config pass_through);
use Pod::Usage;
use Pod::Simple::Pandoc;
use Pandoc;
use Pandoc::Elements;
use Scalar::Util qw(reftype blessed);
use JSON;
use Carp;

use parent 'Exporter';
our @EXPORT    = qw(pod2pandoc);
our @EXPORT_OK = qw(pod2pandoc parse_arguments);

sub parse_arguments {
    my %opt;
    Getopt::Long::GetOptionsFromArray(
        \@_,       \%opt,            'help|h|?', 'version',
        'parse=s', 'podurl=s',       'ext=s',    'index=s',
        'wiki',    'default-meta=s', 'update',   'quiet',
        'name',
    ) or exit 1;
    pod2usage(1) if $opt{help};
    if ( $opt{version} ) {
        say "$0 $VERSION";
        exit 0;
    }

    my @input = @_ ? () : '-';

    my ($index) = grep { $_[$_] eq '--' } ( 0 .. @_ - 1 );

    if ( defined $index ) {
        push @input, shift @_ for 0 .. $index - 1;
        shift @_;    # --
    }
    else {
        push( @input, shift @_ ) while @_ and $_[0] !~ /^-./;
    }

    if ( $opt{parse} and $opt{parse} ne '*' ) {
        $opt{parse} = [ split /[, ]+/, $opt{parse} ];
    }

    return ( \@input, \%opt, @_ );
}

# TODO: move to Pandoc::Elements
sub _add_default_meta {
    my ( $doc, $meta ) = @_;
    return unless $meta;
    $doc->meta->{$_} //= $meta->{$_} for keys %$meta;
}

sub _default_meta {
    my $meta = shift || {};
    return $meta if ref $meta;

    # read default metadata from file
    if ( $meta =~ /\.json$/ ) {
        open( my $fh, "<:encoding(UTF-8)", $meta )
          or croak "failed to open $meta";
        local $/;
        $meta = decode_json(<$fh>);
        for ( keys %$meta ) {
            $meta->{$_} = metadata( $meta->{$_} );
        }
        return $meta;
    }
    else {
        pandoc->require('1.12.1');
        return pandoc->file($meta)->meta;
    }
}

sub pod2pandoc {
    my $input = shift;
    my $opt   = ref $_[0] ? shift : {};
    my @args  = @_;

    $opt->{meta} =
      _default_meta( $opt->{meta} // delete $opt->{'default-meta'} );

    # directories
    if ( @$input > 0 and -d $input->[0] ) {
        my $target = @$input > 1 ? pop @$input : $input->[0];

        my $modules = Pod::Pandoc::Modules->new;
        foreach my $dir (@$input) {
            my $found = Pod::Simple::Pandoc->new->parse_modules($dir);
            warn "no .pm, .pod or Perl script found in $dir\n"
              unless %$found or $opt->{quiet};
            $modules->add( $_ => $found->{$_} ) for keys %$found;
        }

        _add_default_meta( $modules->{$_}, $opt->{meta} ) for %$modules;

        $modules->serialize( $target, $opt, @args );
    }

    # files and/or module names
    else {
        my $parser = Pod::Simple::Pandoc->new(%$opt);
        my $doc = $parser->parse_and_merge( @$input ? @$input : '-' );

        _add_default_meta( $doc, $opt->{meta} );

        if (@args) {
            pandoc->require('1.12.1');
            $doc->pandoc_version( pandoc->version );
            print $doc->to_pandoc(@args);
        }
        else {
            print $doc->to_json, "\n";
        }
    }
}

1;
__END__

=head1 NAME

App::pod2pandoc - implements pod2pandoc command line script

=head1 SYNOPSIS

  use App::pod2pandoc;

  # pod2pandoc command line script
  my ($input, $opt, @args) = parse_arguments(@ARGV);
  pod2pandoc($input, $opt, @args);

  # parse a Perl/Pod file and print its JSON serialization
  pod2pandoc( ['example.pl'], {} );

  # parse a Perl/Pod file and convert to HTML with a template
  pod2pandoc( ['example.pl'], {}, '--template', 'template.html' );

  # process directory of Perl modules
  pod2pandoc( [ lib => 'doc'], { ext => 'html' }, '--standalone' );

=head1 DESCRIPTION

This module implements the command line script L<pod2pandoc>.

=head1 FUNCTIONS

=head2 pod2pandoc( \@input, [ \%options, ] \@arguments )

Processed input files with given L<pod2pandoc> options (C<data-sections>,
C<podurl>, C<ext>, C<wiki>, C<meta>, C<update>, and C<quiet>) .  Additional
arguments are passed to C<pandoc> executable via module L<Pandoc>.

Input can be either files and/or module names or directories to recursively
search for C<.pm> and C<.pod> files. If no input is specified, Pod is read from
STDIN. When processing directories, the last input directory is used as output
directory.

This function is exported by default.

=head2 parse_arguments( @argv )

Parses options and input arguments from given command line arguments. May
terminate the program with message, for instance with argument C<--help>.

=head1 SEE ALSO

This module is part of L<Pod::Pandoc> and based on the modules
L<Pod::Simple::Pandoc>, L<Pod::Pandoc::Modules>, L<Pandoc::Element> and
L<Pandoc>.

=cut
