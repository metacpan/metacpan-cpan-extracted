## no critic (ControlStructures::ProhibitPostfixControls)
package Software::Policies::License;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project policy file: License

our $VERSION = '0.002';

use Carp;
use Module::Load qw( load );

# use Software::License;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub create {
    my ( $self, %args ) = @_;
    my $class   = $args{'class'}   // 'Perl_5';
    my $version = $args{'version'} // '1';
    my $format  = $args{'format'}  // 'text';
    my %attributes;
    my $attrs = $args{'attributes'} // {};
    $attributes{'holder'}                = $attrs->{'authors'}->[0] if $attrs->{'authors'};
    $attributes{'year'}                  = $attrs->{'year'}         if $attrs->{'year'};
    $attributes{'perl_5_double_license'} = $attrs->{'perl_5_double_license'}
      if $attrs->{'perl_5_double_license'};
    croak q{Missing attribute 'holder'}
      if ( !defined $attributes{'holder'} );
    my $txt;

    if ( $class eq 'Perl_5' && $attributes{'perl_5_double_license'} ) {
        load 'Software::License::GPL_3';           # filename: LICENSE-GPL-3
        load 'Software::License::Artistic_2_0';    # filename: LICENSE-Artistic-2.0
        return {
            policy   => __PACKAGE__ =~ m/.*::([[:word:]]{1,})$/msx,
            class    => 'GPL',
            version  => 1,
            text     => Software::License::GPL_3->new( \%attributes )->license,
            filename => 'LICENSE-GPL-3',
            format   => 'text',
          },
          {
            policy   => __PACKAGE__ =~ m/.*::([[:word:]]{1,})$/msx,
            class    => 'Artistic',
            version  => '1.0',
            text     => Software::License::Artistic_2_0->new( \%attributes )->license,
            filename => 'LICENSE-Artistic-2.0',
            format   => 'text',
          };
    }
    else {
        my $module = 'Software::License::' . $class;
        load $module;
        $txt = $module->new( \%attributes );
    }
    return {
        policy   => __PACKAGE__ =~ m/.*::([[:word:]]{1,})$/msx,
        class    => $class,
        version  => $version,
        text     => $txt->license,
        filename => _filename($format),
        format   => $format,
    };
}

sub get_available_classes_and_versions {
    return {
        'Perl_5' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'text' => 1,
            },
        },
    };
}

sub _filename {
    my ($format) = @_;
    my %formats = ( 'text' => 'LICENSE', );
    return $formats{$format};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::License - Create project policy file: License

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Only Perl_5 License supported currently.

=begin Pod::Coverage




=end Pod::Coverage

=begin stopwords




=end stopwords

=head1 METHODS

=head2 new

=head2 create

Create the policy.

Options:

=over 8

=item class

Available classes: Please see licenses in L<Software::License>.
Default: Perl_5

=item version

Available versions: 1 (default).

=item format

Available formats: text (default).

=item options

Required options:

=over 8

=item perl_5_double_license

Instead of F<LICENSE>, create files F<LICENSE-GPL-3> and F<LICENSE-Artistic-2.0>.
GitHub recognizes these.

=back

Non-mandatory options:
See L<Software::License>.

=over 8

=back

=back

=head2 get_available_classes_and_versions

Return a hash with classes as keys. Example:

    {
        'Perl_5' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'text' => 1,
            },
        },
    }

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
