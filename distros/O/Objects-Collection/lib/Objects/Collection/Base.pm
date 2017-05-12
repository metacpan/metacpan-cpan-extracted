package Objects::Collection::Base;

#$Id: Base.pm,v 1.3 2006/04/27 14:56:19 zag Exp $

=head1 NAME

 Objects::Collection::Base - abstract class.

=head1 SYNOPSIS

    use Objects::Collection::Base;
    @Objects::Collection::ISA = qw(Objects::Collection::Base);

=head1 DESCRIPTION

Abstract class.

=head1 METHODS

=cut


use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
require Exporter;
@Objects::Collection::Base::ISA    = qw(Exporter);
@Objects::Collection::Base::EXPORT = qw(attributes);
$Objects::Collection::Base::VERSION = '0.01';

sub attributes {
    my ($pkg) = caller;
    no strict;
    croak "Error: attributes() invoked multiple times"
      if scalar @{"${pkg}::__ATTRIBUTES__"};

    @{"${pkg}::__ATTRIBUTES__"} = @_;
    my $code = "";
    foreach my $attr (@_) {
        if ( UNIVERSAL::can( $pkg, "$attr" ) ) {
            next;
        }
        $code .= _define_accessor( $pkg, $attr );
    }
    eval $code;
}

sub _define_accessor {
    my ( $pkg, $attr ) = @_;
    my $code = qq{
    package $pkg;
    sub $attr {                                      # Accessor ...
      my \$self=shift;
      \@_ ? \$self->{ Var }->{ $attr } = shift : \$self->{ Var }->{ $attr };
    }
  };
    $code;
}

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    return ( $stat = $self->_init(@_) ) ? $self : $stat;
}

sub _init {
    my $self = shift;
    return 1;
}


# Preloaded methods go here.

1;
__END__


=head1 SEE ALSO

Objects::Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
