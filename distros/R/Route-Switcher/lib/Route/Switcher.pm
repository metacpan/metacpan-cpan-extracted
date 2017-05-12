package Route::Switcher;
use 5.008001;
use strict;
use warnings;
use base 'Exporter';
our $VERSION = "0.02";

our @EXPORT = qw/switcher/;

my $CALLER = caller;
my @methods;
my %ORIG_METHOD;
our ($base_path,$base_class);

sub init {
    my $class = shift;
    my @methods  = @_;
    $class->methods(@_);

    no strict 'refs';
    no warnings 'redefine';
    for my $method (@methods) {
        *{"$CALLER\::$method"} = sub  {
            my $path = ($base_path  || '') . shift;
            my $dest = ($base_class || '') . shift;
            $ORIG_METHOD{$method}->($path,$dest,@_);
        };
    }
}

sub switcher {
    local $base_path = shift;
    local $base_class = shift;
    my $code = shift;
    $code->();
}

sub methods {
    my $class = shift;
    if (@_) {
        @methods = @_;
        _cache_original_method();
    }
    return @methods;
}


sub _cache_original_method {
    for my $method (@methods) {
        next unless( my $sub = $CALLER->can($method));
        $ORIG_METHOD{$method} = $sub;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Route::Switcher - give feature of nest to other router module

=head1 SYNOPSIS

    package TestDispatcher;
    use Your::Router qw/ get post /; #export get,post method
    use Route::Switcher;

    # override get,post method in switcher method
    Route::Switcher->init(qw/get post/);

    switcher '/user_account' => 'Hoge::UserAccount', sub {
        get('/new'  => '#new'); # equal to get('/user_account/new' => 'Hoge::UserAccount#new');
        post('/new'  => '#new');
        get('/edit' => '#edit');
    };

    switcher '/post/' => 'Hoge::Post', sub {
        get('new'  => '#new');
        post('new'  => '#new');
        get('edit' => '#edit');
    };

    switcher '' => '', sub {
        get('new'  => 'NoBase#new');
    };

    # original methods of Your::Router
    get('/no_base'  => 'NoBase#new');
    post('/no_base'  => 'NoBase#new');


=head1 DESCRIPTION

Route::Switcher give feature of nest to other router module.

=head1 METHODS

=head2 init

set name of overridden method.

=head2 switcher

argument of switcher and argument of overriden method are joined within the dynamic scope of switcher method.

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass@cpan.orgE<gt>

=cut

