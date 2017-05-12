package Mojolicious::Plugin::MoreUtilHelpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Collection;
use Mojo::DOM;
use Mojo::Util;

use Lingua::EN::Inflect;

our $VERSION = '0.06';

sub register {
    my ($self, $app, $defaults) = @_;

    $app->helper(count => sub {
	my ($c, $item, $type) = @_;
	my $count = $item;
	return unless defined $item;

	my $tr    = sub { lc( (split /::/, ref(shift))[-1] ) };

	if(ref($item) eq 'ARRAY') {
	    $count = @$item;
	    $type  = $tr->($item->[0]) unless $type;
	}

	$type ||= $tr->($item);
	return "$count " . Lingua::EN::Inflect::PL($type, $count);
    });

    $app->helper(paragraphs => sub {
	my ($c, $text) = @_;
	return unless $text;

	my $html = join '', map $c->tag('p', $_), split /^\s*\015?\012/m, $text;
	return $c->b($html);
    });


    my $maxwords = $defaults->{maxwords};
    $app->helper(maxwords => sub {
	my $c    = shift;
	my $text = shift;
	my $n    = shift // $maxwords->{max};

	return $text unless $text and $n and $n > 0;

	my $omited = shift // $maxwords->{omit} // '...';
	my @words  = split /\s+/, $text;
	return $text unless @words > $n;

	$text = join ' ', @words[0..$n-1];

	if(@words > $n) {
	    $text =~ s/[[:punct:]]$//;
	    $text .= $omited;
	}

	return $text;
    });

    my $sanitize = $defaults->{sanitize};
    $app->helper(sanitize => sub {
	my $c    = shift;
	my $html = shift;
	return unless $html;

	my %options = @_;

	my (%tags, %attr);
	my $names = $options{tags} // $sanitize->{tags};
	@tags{@$names} = (1) x @$names if ref $names eq 'ARRAY';

	$names = $options{attr} // $sanitize->{attr};
	@attr{@$names} = (1) x @$names if ref $names eq 'ARRAY';

	my $doc = Mojo::DOM->new($html);
        if (! %tags) {
	    my $txt = $doc->all_text;
            $txt =~ s/\s+/ /g;
            $txt =~ s/^ //;
            $txt =~ s/ $//;
            return $txt;
        }

	for my $node (@{$doc->descendant_nodes}) {
	    if($node->tag && !$tags{ $node->tag }) {
		$node->strip;
		next;
	    }

	    if(%attr) {
		for my $name (keys %{$node->attr}) {
		    delete $node->attr->{$name} unless $attr{$name};
		}
	    }
	}

	return $c->b($doc->to_string);
    });

    $app->helper(trim_param => sub {
	my $c = shift;
	return unless @_;

	my $trim = sub {
	    my $name = shift;
	    my $vals = $c->every_param($name);

	    $c->param($name => @$vals == 1 ?
		      Mojo::Util::trim($vals->[0]) :
		      [ map Mojo::Util::trim($_), @$vals ]);
	};

	my %params;
	my $names = $c->req->params->names;
	@params{ @$names } = (1) x @$names;

	for my $name (@_) {
	    if(ref($name) ne 'Regexp') {
		$trim->($name);
		next;
	    }

	    for(keys %params) {
		next unless $_ =~ $name;

		$trim->($_);
		delete $params{$_};
	    }
	}
    });

    $app->helper(collection => sub {
	my $c = shift;
	my @data = ( @_ == 1 && ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_ );
	return Mojo::Collection->new(@data == 1 && !defined $data[0] ? () : @data );
    });

    if($defaults->{collection}->{patch}) {
	$app->helper(c => sub { shift->collection(@_) });
    }

}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::MoreUtilHelpers - Methods to format, count, sanitize, etc...

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('MoreUtilHelpers', %defaults);

  # Mojolicious::Lite
  plugin 'MoreUtilHelpers', %defaults;

  $self->count(10, 'user');     # 10 users
  $self->count([User->new]);    # 1 user
  $self->paragraphs($text);     # <p>line 1</p><p>line 2</p>...
  $self->maxwords('a, b, c', 2) # a, b...
  $self->sanitize($html);       # remove all HTML

  # keep <a> and <p> tags
  $self->sanitize($html, tags => ['a','p']);

  # future calls to param($name[n]) return trimmed values
  $self->trim_param(@names);

  # DWIM Mojo::Collection
  $self->collection(@data);
  $self->collection($data);

=head1 MOJOLICIOUS VERSION

This version requires Mojolicious >= 7.0. If you're using an earlier version of Mojolicious
you must use L<version 0.05|https://github.com/sshaw/Mojolicious-Plugin-MoreUtilHelpers/tree/v0.05>
or lower of this module.

=head1 METHODS

Defaults can be set for certain methods when the plugin is loaded.

  $self->plugin('MoreUtilHelpers', maxwords => { omit => ' [snip]' },
    			           sanitize => { tags => ['code', 'pre', 'a'] });

By default and, unless stated otherwise, no defaults are set. See the method docs for more info.

=head2 count

  $self->count(10, 'user');           # 10 users
  $self->count([User->new]);          # 1 user
  $self->count([User->new], 'Luser'); # 1 Luser

Use the singular or plural form of the word based on the number given by the first argument.
If a non-empty array of objects are given the lowercase form of the package's basename is used.

=head2 collection

  $self->collection(1,2,3)
  $self->collection([1,2,3]);
  $self->collection(undef);  # empty collection

DWIM (B<D>o B<W>hat B<I> B<M>ean) L<Mojo::Collection> creation.
Currently C<Mojo::Collection> does not differentiate between C<undef> and array ref arguments. For example:

  $self->c(1)->to_array;         # [1]
  $self->c([1])->to_array;       # [[1]]
  $self->c(undef)->to_array;     # [undef]
  $self->c([1,2,[3]])->to_array; # [[1,2,[3]]]

Using C<collection> to create a C<Mojo::Collection> will give you the following:

  $self->collection(1)->to_array;         # [1]
  $self->collection([1])->to_array;       # [1]
  $self->collection(undef)->to_array;     # []
  $self->collection([1,2,[3]])->to_array; # [1,2,[3]]

=head3 Making This Behavior The Default

To replace L<< the C<c> helper|Mojolicious::Plugin::DefaultHelpers/c >> with C<collection>:

  $self->plugin('MoreUtilHelpers', collection => { patch => 1 });

This B<does not> replace L<Mojo::Collection::c>.

=head2 maxwords

  $self->maxwords($str, $n);
  $self->maxwords($str, $n, '&hellip;');

Truncate C<$str> after C<$n> words. If C<$str> has more than C<$n> words traling
punctuation characters are stripped from the C<$n>th word and C<'...'> is appended.
An alternate ommision character can be given as the third option.

=head3 Setting Defaults

  $self->plugin('MoreUtilHelpers', maxwords => { omit => ' [snip]', max => 20 });

=head2 paragraphs

  $self->paragraphs($text);

Wrap lines seperated by empty C<\r\n> or C<\n> lines in HTML paragraph tags (C<p>).
For example: C<A\r\n\r\nB\r\n> would be turned into C<< <p>A\r\n</p><p>B\r\n</p> >>.

The returned HTML is assumed to be safe and is wrapped in a L<Mojo::ByteStream>.

=head2 sanitize

  $self->sanitize($html);
  $self->sanitize($html, tags => ['a','p'], attr => ['href']);

Remove all HTML tags in the string given by C<$html>. If C<tags> and -optionally- C<attr>
are given, remove everything but those tags and attributes.

The returned HTML is assumed to be safe and is wrapped in a L<Mojo::ByteStream>.

=head3 Setting Defaults

  $self->plugin('MoreUtilHelpers', sanitize => { tags => ['a','p'], attr => ['href'] });

=head2 trim_param

  $self->trim_param(@names);
  $self->trim_param(qr{user\.});

For each param name in C<@names>, make future calls to L<Mojolicious::Controller/param>
return these params' values without leading and trailing whitespace. If an element of C<@names>
is a regexp all matching param names will be processed.

In some cases it may be best to add this to your routes via L<Mojolicious::Routes/under>:

  my $account = $self->routes->under(sub {
    shift->trim_param('name', 'email', 'phone');
    return 1;
  });

  $account->post('save')->to('account#save');
  $account->post('update')->to('account#update');

Now calling C<< $self->param >> in these actions for C<'name'>, C<'email'> or C<'phone'> will
return a trimmed result.

Leading/trailing whitespace is removed by calling L<Mojo::Util/trim>.

=head1 SEE ALSO

L<Lingua::EN::Inflect>, L<Number::Format>, L<List::Cycle>, L<Mojolicious::Plugin::UtilHelpers|https://github.com/sharifulin/mojolicious-plugin-utilhelpers>

=head1 AUTHOR

Skye Shaw (skye.shaw [AT] gmail.com)

=head1 LICENSE

Copyright (c) 2012-2014 Skye Shaw. This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
