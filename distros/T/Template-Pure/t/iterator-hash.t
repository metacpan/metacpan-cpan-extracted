use Test::Most;
use Template::Pure;
use Mojo::DOM58;


ok my $html = qq[
  <dl id='dlist'>
    <section>
    <dt>property</dt>
    <dd>value</dd>
    </section>
  </dl>];

ok my $pure = Template::Pure->new(
  template => $html,
  directives => [
    'dl#dlist section' => {
      'property<-author' => [
        'dt' => 'i.index',
        'dd' => 'property',
      ],
      order_by => sub {
        my ($pure, $hashref, $a_key, $b_key) = @_;
        $a_key cmp $b_key;
      }
    },
  ]
);

ok my %data = (
  author => {
    first_name => 'John',
    last_name => 'Napiorkowski',
    aaa => undef,
    email => 'jjn1056@yahoo.com',
  },
);


ok my $string = $pure->render(\%data);
ok my $dom = Mojo::DOM58->new($string);

#warn $string;

is $dom->find('section')->[0]->at('dt')->content, 'aaa';
#is $dom->find('section')->[0]->at('dd')->content, 'bbb';
is $dom->find('section')->[1]->at('dt')->content, 'email';
is $dom->find('section')->[1]->at('dd')->content, 'jjn1056@yahoo.com';
is $dom->find('section')->[2]->at('dt')->content, 'first_name';
is $dom->find('section')->[2]->at('dd')->content, 'John';
is $dom->find('section')->[3]->at('dt')->content, 'last_name';
is $dom->find('section')->[3]->at('dd')->content, 'Napiorkowski';


done_testing; 
