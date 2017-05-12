package User;

use Mojo::Base -base;

has 'age';
has 'bio';
has 'name';
has 'admin';
has 'orders';

package TestHelper;

use Mojo::Base -strict;
use Test::More;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(render_input user dom is_field_count is_field_attrs);

sub dom { shift->tx->res->dom }	# For Test::Mojo

sub is_field_count
{
    my ($t, $field, $expect) = @_;
    # can't say ->input->size unless input() exists
    is(dom($t)->find($field)->size, $expect, "$field count");
}

sub is_field_attrs
{
    my ($t, $field, $expect) = @_;
    my $e = dom($t)->at($field);

    my $attrs;
    if($e) {
	# attrs removed after 4.50
        $attrs = $e->can('attrs') ? $e->attrs : $e->attr;
	# Mojolicious >= 5.73 generates HTML5, which will cause is_deeply to fail for
	# atributes without a value, like 'checked' or 'selected'
	for(keys %$attrs) {
	  $attrs->{$_} = $_ if exists $attrs->{$_} and !defined $attrs->{$_};
	}
    }

    $attrs //= {};

    is_deeply($attrs, $expect, "$field attributes");
}

sub user
{
    my %attribs = @_;
    my %defaults = (admin => 1,
		    age   => 101,
		    bio   => 'Proprietary and confidential',
		    name  => 'sshaw',
		    orders => [ { id => 1 }, { id => 2 } ]);
    %attribs = (%defaults, %attribs);

    User->new(%attribs);
}

sub render_input
{
    my $c = shift;
    my $input = shift;

    my %options = @_;
    my $user = $c->param('user');
    $options{stash} ||= { user => user(%$user) };

    $c->stash(%{$options{stash}});
    $c->render(text => $c->field('user.name')->$input(@{$options{input}}));
}

1;
