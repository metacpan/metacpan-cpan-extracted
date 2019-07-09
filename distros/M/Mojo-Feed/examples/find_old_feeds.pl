#!/usr/bin/env perl

use 5.020;
use Mojo::Feed::Reader;
use Mojo::UserAgent::Role::Queued;

my $fr =
  Mojo::Feed::Reader->new( ua => Mojo::UserAgent->new->with_roles(q{+Queued}) );
my @subs = $fr->parse_opml(shift);    # t/samples/subscriptions.xml
for my $sub ( sort { $a->{xmlUrl} cmp $b->{xmlUrl} } @subs ) {
    my $f = eval { $fr->parse( Mojo::URL->new( $sub->{xmlUrl} ) ); };
    if ($@) {
        say( $sub->{title} || $sub->{text} ), $sub->{xmlUrl}, q{ failed because }, $@;
    }
    elsif ( $f && $f->items->size && (my $top = $f->items->first) ) {
        say $f->source, q{ }, $f->title, q{ },
          $top->published ? Mojo::Date->new( $top->published ) : $top->description;
    }
    else {
        say ($sub->{title} || $sub->{text}), q{ }, $sub->{xmlUrl}, q{ Empty feed?}; 
    }
}
