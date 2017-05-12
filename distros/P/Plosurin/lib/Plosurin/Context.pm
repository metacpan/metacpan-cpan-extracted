#===============================================================================
#
#  DESCRIPTION:  maintain collection of files and templates
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Plosurin::Context - maintain collection of files and templates

=head1 SYNOPSIS

    new Plosurin::Context( <Plo::File1>,<Plo::File2> );

=head1 DESCRIPTION

Plosurin::Context - maintain collection of files and templates

=cut

# while export is going
package Plosurin::Context;
use strict;
use warnings;

=head2 new
    
    #init colection
    new Plosurin::Context( <Plo::File1>,<Plo::File2> );

=cut

sub new {
    my $class = shift;
    bless( { src => [@_] }, ref($class) || $class );
}

=head2 name2tmpl

return hash all templates
 {
    
 }
=cut

sub name2tmpl {
    my $self = shift;
    my %res  = ();
    foreach my $file ( @{ $self->{src} } ) {
        for ( $file->templates ) {
            my $full_name = $file->namespace . $_->name;
            $res{$full_name} = $_;
        }
    }
    \%res;
}

=head2 get_template_by_name

get by .name -> absolute -> rerurn ref to template

=cut

sub get_template_by_name {
    my $self = shift;
    my $name = shift || return undef;

    #get current namespace
    if ( $name =~ /^\./ ) {

        #uless defined namespace
        #get from first File
        my $namespace = $self->{namespace} || $self->{src}->[0]->namespace;
        $name = $namespace . $name;
    }
    return $self->name2tmpl->{$name};
}

=head2 get_perl5_name $template_object

get perl5 full path

=cut

sub get_perl5_name {
    my $self = shift;
    my $tmpl = shift || return;
    ( my $p5name = $tmpl->full_name ) =~ tr/\./_/;
    $p5name;
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

