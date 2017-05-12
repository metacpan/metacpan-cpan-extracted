#===============================================================================
#
#  DESCRIPTION:  Perl 5 Writer
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Plosurin::Writer::Perl5 - perl5 writer

=head1 SYNOPSIS

    my $p5  = new Plosurin::To::Perl5(
           'context' => $ctx,
           'writer'  => new Plosurin::Writer::Perl5,
           'package' => $package,
        );

  
=head1 DESCRIPTION

Plosurin::Writer::Perl5 - perl6 writer

=cut

package Plosurin::Writer::Perl5;
use strict;
use warnings;
use v5.10;

sub new {
    my $class = shift;
    my $ini = $#_ == 0 ? shift : {@_};
    $ini->{varstack} = [ { name => 'res', inited => 0 } ];
    $ini->{ident} = 0;
    $ini->{var_map} //={};
    bless( $ini, ref($class) || $class );

}

#ident for generated code
sub inc_ident {
    $_[0]->{ident} += 4;
}

sub ident { $_[0]->{ident} }

sub dec_ident {
    my $self = shift;
    $self->{ident} -= 4 if $self->{ident} > 3;
}

sub say {
    my $self = shift;
    return $self->print( @_, "\n" );
}

sub print {
    my $self = shift;
    $self->{code} .= " " x $self->ident . "@_";
}

sub pushOtputVar {
    my ( $self, $var ) = @_;
    push @{ $self->{varstack} }, { name => $var, value => '' };

}

sub popOtputVar {
    my ( $self, $var ) = @_;
    pop @{ $self->{varstack} };    #, {name=> $var, value=>''};
}

sub initOutputVar {
    my $self = shift;
    return if $self->currentVar->{inited};
    $self->say( 'my $' . $self->currentVar->{name} . ' =  "";' );
    $self->currentVar->{inited}++;
}

sub currentVar {
    my $self = shift;
    $self->{varstack}[-1];
}

sub appendOutputVar {
    my $self = shift;
    my $data = join '', @_;
    my $v    = $self->currentVar;
    my $name = $v->{name};
    unless ( $v->{inited} ) {
        $self->say( 'my $' . $name . ' = ' . $data . ';' );
        $v->{inited}++;
    }
    else {
        $self->say( '$' . $name . ' .= ' . $data . ';' )

    }
}

sub var_map {
    my $self = shift;
    return $self->{var_map};
}

sub set_var_map {
    my ($self, $tmp_var, $new_var) = @_;
    $self->var_map()->{$tmp_var} =$new_var;
}
1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

