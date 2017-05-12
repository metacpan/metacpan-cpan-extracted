#===============================================================================
#  DESCRIPTION:
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================
package CustomCode;
use strict;
use warnings;
use base 'Perl6::Pod::FormattingCode';
1;

package CustomCodeCF;
use strict;
use warnings;
use base 'Perl6::Pod::FormattingCode';

sub to_mem {
    my ( $self, $parser, $para ) = @_;
    return { name => "ok", attr => $self->get_attr };
}
sub to_xml {
    my ( $self, $parser, $para ) = @_;
    my $ok = $parser->mk_element("ok");
    %{$ok->attrs_by_name()} = %{$self->get_attr};
    return $ok;
}
1;

package CustomCodeCB;
use strict;
use warnings;
use base 'Perl6::Pod::Block';

sub to_mem {
    my ( $self, $parser, $para ) = @_;
    return { name => "ok", attr => $self->get_attr };
}
1;

package CustomCodeFF;
use strict;
use warnings;
use base 'Perl6::Pod::FormattingCode';

sub to_mem1 {
    my ( $self, $parser, $para ) = @_;
    return { name => "ok", attr => $self->get_attr };
}
1;

package T::FormattingCode::M;
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use base "T::FormattingCode";

sub startup : Test(startup=>1) {
    use_ok('Perl6::Pod::Parser::CustomCodes');
}

sub check_use : Test(2) {
    my $test = shift;
    my ( $p, $f, $o ) = $test->parse_mem(<<TXT);
=use   CustomCode TT<>
=head1 Test M<TT: test_code>
TXT
    is $p->current_context->use->{'TT<>'}, 'CustomCode',
      'define custom formatcode';
    is_deeply $o,
      [
        {
            'name'   => 'head1',
            'childs' => [
                'Test ',
                {
                    'name'   => 'M',
                    'childs' => ['TT: test_code'],
                    'attr'   => {}
                },
                ''
            ],
            'attr' => {}
        }
      ];
}

sub resolve_filter : Test {
    my $test = shift;
    my $o = $test->parse_mem( <<TXT, 'Perl6::Pod::Parser::CustomCodes' );
=use CustomCode TT<>
=para sds M<TT: test_code>
TXT
    is_deeply $o,
[
          {
            'name' => 'para',
            'childs' => [
                          'sds ',
                          {
                            'name' => 'TT',
                            'childs' => [
                                          'test_code'
                                        ],
                            'attr' => {}
                          },
                          ''
                        ],
            'attr' => {}
          }
        ];
}

sub custom_code_export_mem : Test {
    my $test = shift;
    my ( $p, $f, $o ) =
      $test->parse_to_xml( <<TXT, 'Perl6::Pod::Parser::CustomCodes' );
=use CustomCodeCF CF
=begin head1
M<CF:eer>
=end head1
TXT
    $test->is_deeply_xml( $o, q#<head1 pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'><ok />
</head1>#)

}
sub code_preconfig : Test {
    my $test  =shift;
    my ($p, $f, $o) = $test->parse_to_xml(<<TXT, 'Perl6::Pod::Parser::CustomCodes');
=use CustomCodeCB OO
=config OO :w1
=begin para
M<OO: r>
=end para
TXT
$test->is_deeply_xml ($o,
q#<para pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'><OO pod:type='block' w1='1'>r</OO>
</para>#)

}

sub multiline_M : Test {
    my $test = shift;
    my $o = $test->parse_mem(<<TXT, 'Perl6::Pod::Parser::CustomCodes');
=use CustomCode FF<>
=for head1
M<FF: test sdsd
sdsdsd
sdsd >
TXT
is_deeply $o,  [
          {
            'name' => 'head1',
            'childs' => [
                          {
                            'name' => 'FF',
                            'childs' => [
                                          'test sdsd
sdsdsd
sdsd '
                                        ],
                            'attr' => {}
                          },
                          ''
                        ],
            'attr' => {}
          }
        ];
}
1;

