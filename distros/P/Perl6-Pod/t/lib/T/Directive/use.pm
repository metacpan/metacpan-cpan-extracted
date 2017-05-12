#===============================================================================
#
#  DESCRIPTION:  Test use directive;
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package UserDefined::TT;
use strict;
use warnings;
use base 'Perl6::Pod::Block';

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);
    return $self

}

sub start {
    my $self = shift;
    my $p    = shift;
    $p->{ATTR} = $self->get_class_options()

      #   warn "!!! $self";
}
1;

package UserDefined::Lib;
use strict;
use warnings;
our $PERL6POD = <<POD;
=begin pod
=use UserDefined::TF ttr
=use UserDefined::TF ttr2
=end pod
POD
1;

package UserDefined::TE;
use strict;
use warnings;
use base 'Perl6::Pod::Block';
1;

package UserDefined::TF;
use strict;
use warnings;
use base 'Perl6::Pod::Block';
1;

package T::Directive::use;
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use base "TBase";
use Perl6::Pod::Parser::Utils qw(parse_URI);

sub u01_register_mod : Test {
    my $t = shift;
    my ( $p, $f, $x ) = $t->parse_to_xml(<<T);
=begin pod
=use UserDefined::TT
=use UserDefined::TT Tt
=use UserDefined::TT Ta :attr
=use UserDefined::TE :attr
=end pod
T
    my $ctx = $p->current_context->use;
    is_deeply [ @$ctx{qw/ TT Tt Ta TE /} ],
      [
        'UserDefined::TT', 'UserDefined::TT',
        'UserDefined::TT', 'UserDefined::TE'
      ];

}

sub u02_register_format_code : Test {
    my $t = shift;
    my ( $p, $f, $x ) = $t->parse_to_xml(<<T);
=begin pod
=use UserDefined::TF Q<>
=use UserDefined::TF A<> :attr
=end pod
T
    my $ctx = $p->current_context->use;
    is_deeply [ @$ctx{qw/ Q<> A<> /} ],
      [ 'UserDefined::TF', 'UserDefined::TF' ];
}

sub u02_class_attr : Test(3) {
    my $t = shift;
    my ( $p, $f, $x ) = $t->parse_to_xml(<<T);
=begin pod
=use UserDefined::TT Test :name(1) :aaa
=use UserDefined::TT Test1 :deleted
=use UserDefined::TT Test1
=Test sd
=end pod
T
    my $ctx        = $p->current_context->use;
    my $class_opts = $p->current_context->class_opts;
    is $class_opts->{Test}, ':name(1) :aaa';
    ok !$class_opts->{Test1}, 'check overwrite';
    is_deeply $p->{ATTR},
      {
        'name' => 1,
        'aaa'  => 1
      };
}

sub u041_schemes_parse : Test(3) {
    my $t = shift;
    ok !parse_URI('Pod::Insertion::Name')->{is_external},
      'is_external Pod::Insertion::Name';
    is parse_URI('pod:Pod::Insertion::Name')->{scheme}, 'pod',
      'scheme pod:Pod::Insertion::Name';
    ok parse_URI('http://www.website.com/Pod/Insertion/Name.pod')
      ->{is_external},
      'is_external http://www.website.com/Pod/Insertion/Name.pod'

}

sub u04_handle_PERL6POD_variable : Test {
    my $t = shift;
    my ( $p, $f, $x ) = $t->parse_to_xml(<<T);
=begin pod
=use UserDefined::Lib
=end pod
T
    my $ctx = $p->current_context->use;
    is_deeply [ @$ctx{qw/ttr ttr2 /} ],
      [ 'UserDefined::TF', 'UserDefined::TF' ];
}

1;

