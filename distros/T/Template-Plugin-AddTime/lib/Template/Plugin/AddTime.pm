package Template::Plugin::AddTime;
use strict;
use warnings;

use base qw(Template::Plugin);
our $VERSION = '0.01';

sub new {
    my ($class, $context, $args ) = @_;
    my $filter = sub {
        my $context = shift;
        return sub {
            addtime( @_, $args );
        };
    };
    $context->define_filter('addtime', [ $filter => 1 ]);
    return \&addtime;
}

sub addtime_wrap {
    my ($context, @args) = @_;
    sub {
        my $to = shift;
        return addtime( $to, @_ );
    };
}

sub addtime {
    my ($to,$base) = @_;
    $base ||= '';
    my $file = $base . $to;
    my $addtime = (stat( $file ))[9];
    return "$to?$addtime";
}

1;
__END__

=head1 NAME

Template::Plugin::AddTime - TT filter plugin to add file modified time

=head1 SYNOPSIS

 # in template
 [% use AddTime %]
 [% AddTime('t/Template/Plugin/addtime\.t') -%]

 # result
 t/Template/Plugin/addtime\.t\?1231163490


 # or with a base path
 [% USE AddTime('tmpl/static') -%]
 [% '/js/prototype\.js' | addtime -%]

 # adds modified time of tmpl/static/js/prototype\.js
 /js/prototype\.js\?1231163490


=head1 DESCRIPTION

Template::Plugin::AddTime is a TT filter plugin to add file modified time

You may want to use this module when you want to force browsers
not to use their cache when file modified at your server.

=head1 AUTHOR

Masakazu Ohtsuka (mash) E<lt>o.masakazu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
