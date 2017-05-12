package Template::LiquidX::Tag::Random;
# This is based on the example we build in Template::Liquid::Tag
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('random') }

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {
                   type    => 'Syntax',
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
        }
        if !defined $args->{'attrs'} || $args->{'attrs'} !~ m[\S$]o;
    my $s = bless {odds     => $args->{'attrs'},
                   name     => 'Rand-' . $args->{'attrs'},
                   tag_name => $args->{'tag_name'},
                   parent   => $args->{'parent'},
                   template => $args->{'template'},
                   markup   => $args->{'markup'},
                   end_tag  => 'end' . $args->{'tag_name'}
    }, $class;
    return $s;
}

sub render {
    my $s      = shift;
    my $return = '';
    if (!int rand $s->{template}{context}->get($s->{'odds'})) {
        for my $node (@{$s->{'nodelist'}}) {
            my $rendering = ref $node ? $node->render() : $node;
            $return .= defined $rendering ? $rendering : '';
        }
    }
    $return;
}
1;
