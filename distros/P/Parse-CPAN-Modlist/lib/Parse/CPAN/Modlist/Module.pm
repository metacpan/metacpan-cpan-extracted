package Parse::CPAN::Modlist::Module;
use strict;
use vars qw($VERSION);
use Class::Accessor::Fast;
use base qw(Class::Accessor::Fast);
$VERSION = '0.1';

=pod

=head1 NAME

Parse::CPAN::Modlist::Module - object representation of a single module in the 03modlist.data file

=head1 SYNOPSIS

    use Parse::CPAN::Modlist;


    my $p = Parse::CPAN::Modlist->new("t/data/03modlist.data");


    foreach my $name ($p->modules) {
        my $module = $p->module($name);
        print " The module '".$module->name."'".
              " is written by ".$module->author.
              " and is described as '".$module->description.
              "'\n";
    }



=head1 METHODS

The methods are automatically generated from the columns in C<03modlist.data> 
so it's possible that this documentation amy actually be wrong. Please let me
know if this happens.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    return $self;
}



=pod

=head2 name

The name of this module (an alias to modid - the actual column name).

=cut

*name   = \&modid;


=head2 author

The author's CPAN id (an alias to userid - the actual column name).

=cut

*author = \&userid;

=head2 description

A description of the module

=head2 chapter

The category that this module falls under (an alias to chapterid - the actual column name).

See http://www.cpan.org/modules/by-category/ for the categories.

=cut

*chapter = \&chapterid;

=head1 DSLIP methods

DSLIP characters are intended to convey information about the current state of the module.


See http://www.cpan.org/modules/00modlist.long.html#ID1_ModuleListi for details

=head2 d - Development Stage (Note: *NO IMPLIED TIMESCALES*):

=over 4

=item i 

Idea, listed to gain consensus or as a placeholder

=item c 

under construction but pre-alpha (not yet released)

=item a/b 

Alpha/Beta testing

=item R 

Released

=item M 

Mature (no rigorous definition)

=item S 

Standard, supplied with Perl 5

=back

=cut

*d      = \&statd;

=pod

=head2 s - Support Level:

=over 4

=item m 

Mailing-list

=item d 

Developer

=item u 

Usenet newsgroup comp.lang.perl.modules

=item n 

None known, try comp.lang.perl.modules

=back

=cut

*s      = \&stats;

=pod 

=head2 l - Language Used:
    
=over 4

=item p 

Perl-only, no compiler needed, should be platform independent

=item c 

C and perl, a C compiler will be needed

=item h 

Hybrid, written in perl with optional C code, no compiler needed

=item + 

C++ and perl, a C++ compiler will be needed

=item o 

perl and another language other than C or C++

=back

=cut

*l      = \&statl;

=pod 

=head2 i - Interface Style
    
=over 4 

=item f 

plain Functions, no references used

=item h 

hybrid, object and function interfaces available

=item n 

no interface at all (huh?)

=item r 

some use of unblessed References or ties

=item O 

Object oriented using blessed references and/or inheritance

=back

=cut

*i      = \&stati;

=pod

=head2 p - Public License
    
=over 4    

=item p 

Standard-Perl: user may choose between GPL and Artistic

=item g 

GPL: GNU General Public License

=item l 

LGPL: "GNU Lesser General Public License" (previously known as "GNU Library General Public License")

=item b 

BSD: The BSD License

=item a 

Artistic license alone

=item o 

other (but distribution allowed without restrictions)

=back

=cut

*p      = \&statp;


=head1 BUGS

None that I know of.

=head1 COPYING

Distributed under the same terms as Perl itself.

=head1 AUTHOR

Copyright (c) 2004, 

Simon Wistow <simon@thegestalt.org>   

=cut

1;
