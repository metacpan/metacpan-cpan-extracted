use 5.018;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY

package Syntax::Collection::Moose {
our $VERSION = '0.0601';
    use Syntax::Collection::Basic;

    # see http://blogs.perl.org/users/ovid/2013/09/building-your-own-moose.html
    use Moose();
    use MooseX::StrictConstructor();
    use Moops();
    use Kavorka();
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        with_meta => ['has'],
        also      => ['Moose'],
    );

    sub init_meta {
        my $class = shift;
        my %params = @_;
        my $for_class = $params{'for_class'};

        Moose->init_meta(@_);
        MooseX::StrictConstructor->import({ into => $for_class });
        Moops->import(into => $for_class);
        Kavorka->import({ into => $for_class });
    }

    sub has {
        my $meta = shift;
        my $name = shift;
        my %options = @_;

        $options{'is'} //= 'ro';

        foreach (ref $name eq 'ARRAY' ? @$name : $name) {
            $meta->add_attribute($_, %options);
        }
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::Collection::Moose

=head1 VERSION

Version 0.0601, released 2017-10-31.

=head1 STATUS

Deprecated.

=head1 SOURCE

L<https://github.com/Csson/syntax-collection-basic>

=head1 HOMEPAGE

L<https://metacpan.org/release/Syntax-Collection-Basic>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
