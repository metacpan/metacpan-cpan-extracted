#===============================================================================
#
#  DESCRIPTION:  replace variables in expressions with mapped
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package Plosurin::Utl::ExpMapVariables;
use strict;
use warnings;
use Plosurin::AbstractVisiter;
use base 'Plosurin::AbstractVisiter';
use Data::Dumper;
use vars qw($AUTOLOAD);

=head1 SYNOPSYS

        new Plosurin::Utl::ExpMapVariables::
                        vars=>{ 'template_variable'=>"translated_var_name" },
                        params=>{tamplate_param=>0}
=cut

sub Var {
    my $self = shift;

    #variable node
    my $n = shift;
    return if $n->{MAPPED}; #check if current var already mapped
    my $vars = $self->{vars} || {};
    if ( exists $vars->{ $n->{Ident} } ) {
        $n->{Ident} = $vars->{ $n->{Ident} };
    }
    else {

        # use as param
        unless ( exists $self->{params} && defined $self->{params}) {
            $n->{Ident} = 'args{\'' . $n->{Ident} . '\'}';
        }
        else {
            my $params = $self->{params};
            unless ( exists $params->{ $n->{Ident} } ) {
                die "Unknown variable $n->{Ident}";
            }
            else {
                $n->{Ident} = 'args{\'' . $n->{Ident} . '\'}';
            }
        }
    }
    $n->{MAPPED}++;
}

sub __default_method {
    my $self = shift;
    my $n    = shift;
    $self->visit_childs($n);
}
1;

