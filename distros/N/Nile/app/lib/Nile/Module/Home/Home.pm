#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Module::Home::Home;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

use Nile::Module; # automatically extends Nile::Module
use DateTime qw();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# plugin action, return content. url is routed direct or from routes files. url: /home
sub home : GET Action {
    
    my ($self, $app) = @_;
    
    # $app is set to the application context object, same as $self->app inside any method
    #my $app = $self->app;
    
    my $view = $app->view("home");
    
    $view->var(
        fname           =>  'Ahmed',
        lname           =>  'Elsheshtawy',
        email           =>  'sales@mewsoft.com',
        website     =>  'http://www.mewsoft.com',
        singleline      =>  'Single line variable <b>Good</b>',
        multiline       =>  'Multi line variable <b>Nice</b>',
    );
    
    #my $var = $view->block();
    #say "block: " . $app->dump($view->block("first/second/third/fourth/fifth"));
    #$view->block("first/second/third/fourth/fifth", "Block Modified ");
    #say "block: " . $app->dump($view->block("first/second/third/fourth/fifth"));

    $view->block("first", "1st Block New Content ");
    $view->block("six", "6th Block New Content ");

    #say "dump: " . $app->dump($view->block->{first}->{second}->{third}->{fourth}->{fifth});
    
    # module settings from config files
    my $setting = $self->setting();
    
    # plugin session must be enabled in config.xml
    if (!$app->session->{first_visit}) {
        $app->session->{first_visit} = time;
    }
    my $dt = DateTime->from_epoch(epoch => $app->session->{first_visit});
    $view->set("first_visit", $dt->strftime("%a, %d %b %Y %H:%M:%S"));
    
    # save visitors count to the cache
    my $cache = $app->plugin->cache;
    $cache->set("visitor_count", $cache->get("visitor_count") + 1, "1 year");
    $view->set("visitor_count", $cache->get("visitor_count"));
    #----------------------------------
     
    #----------------------------------
    return $view->out();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run action and capture print statements, no returns. url: /home/news
sub news: GET Capture {

    my ($self, $app) = @_;

    say qq{Hello world. This content is captured from print statements.
        The action must be marked by 'Capture' attribute. No returns.};

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run action and capture print statements and the return value. url: /home/info
sub info: GET Command {

    my ($self, $app) = @_;
	
    say qq{This content is captured from print statements. The action marked by 'Command' attribute. };
	
	return qq{This content is the return value on the action.};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# regular method, can be invoked by views:
# <vars type="module" method="Home::Home->welcome" message="Welcome back!" />
sub welcome {

    my ($self, %args) = @_;
    
    my $app = $self->app();

    return "Nice to see you, " . $args{message};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Bug in MooseX::Method::Signatures does not support attributes, waiting fix
# Error: Can't locate object method "attributes" via package "MooseX::Method::Signatures::Meta::Method"
# MooseX::Declare does not seem to work with "MooseX::MethodAttributes because" they both try to override Moose's default metaclass for methods.
# MooseX::MethodAttributes would need to be fixed to respect the original method metaclass, rather than imposing one.
#method hello ($args) : Action {
#   my $app = $self->app;
#   return "Nice to say hello";
#}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
1;
