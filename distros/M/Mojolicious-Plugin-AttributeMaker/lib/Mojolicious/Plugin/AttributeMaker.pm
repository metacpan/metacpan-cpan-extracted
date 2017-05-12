package Mojolicious::Plugin::AttributeMaker;
use Mojo::Base 'Mojolicious::Plugin';
use attributes;
use Module::Load;
use Module::Find qw/findsubmod/;
use feature qw/state/;
use B qw/svref_2object/;
use Scalar::Util qw/blessed/;

=head1 NAME

Mojolicious::Plugin::AttributeMaker - Make attributes for Mojolicious? - easily!

=head1 VERSION

Version 0.07

=cut

our $VERSION = 0.07;

=head1 SYNOPSIS

=head2 Step 1. Include plugin in your app.

=head3 NOTE: Do NOT use this plugin alongside with lite-app!
 
    package TestApp;

    use Mojo::Base 'Mojolicious';
    
    # This method will run once at server start
    sub startup {
        my $self = shift;
        $self->plugin('AttributeMaker',{
            controllers => 'TestApp::Controller'
        });
    }

=head2 Step 2. Configure the plugin.

    {
        # controllers => " Specify the controller class. "
        controllers => 'TestApp::Controller'
    }

=head2 Step 3 - Add your attribute or use pre-created ones from extensions.
 
=head3 Step 3.1 - Create custom attribute in your controller
    
    BEGIN{
        __PACKAGE__->make_attribute(
            Local => sub {
                my ( $package, $method, $plugin, $mojo_app, $attrname, $attrdata ) = @_;
                # $package  - Store the name of controller
                # $method   - Store the name of action
                # $plugin   - Object of Mojolicious::Plugin::AttributeMaker 
                # $mojo_app - Object of your app
                # $attrname - Name of attribute . In current expaple is Local
                # $attrdata - Stores the parameters passed from the attribute
            }
        );
    }
    
If you create extension,you can write the above code without 'BEGIN' section;   

=head3 Step 2.2 - Or use attributes from extensions.

=over 3

=item * Catalyst-like routing

Allows to use attributes like Local, Path, Global.

L<Mojolicious::Plugin::AttributeMaker::Extension::Routing>

=back
    
=cut

sub MODIFY_CODE_ATTRIBUTES {
    my ( $package, $cv, @attrs ) = @_;
    my $config  = config();
    my $cleaner = sub {
        $_[0] =~ m/^'/   ? $_[0] =~ s/^'//   : ();
        $_[0] =~ m/'$/   ? $_[0] =~ s/'$//   : ();
        $_[0] =~ m/^\s+/ ? $_[0] =~ s/^\s+// : ();
        $_[0] =~ m/\s+$/ ? $_[0] =~ s/\s+$// : ();
    };
    foreach my $attr (@attrs) {
        my $attrdata;
        my $cleanattr = $attr;
        if ( $cleanattr =~ m/(\w+)\((\X*)\)$/ ) {    # Attr with params Local(blablabla)
            $cleanattr = $1;
            foreach ( split ',', $2 ) {              # Parsing
                $cleaner->($_);                      # and deleting escape characters in params
                push @$attrdata, $_ if length($_);
            }
        }

        if ( exists $config->{attrs}->{$cleanattr} ) {
            $config->{app}->log->debug("Attribute ${cleanattr} called!");
            $config->{attrs}->{$cleanattr}
              ->( $package, svref_2object($cv)->GV->NAME, $config->{self}, $config->{app}, $cleanattr, $attrdata );
        }
        else {
            $config->{app}->log->error("Attribute ${cleanattr} not found!\n");
        }
    }
    ();
}

sub config {
    shift if @_ > 0 and blessed( $_[0] );
    state $conf;
    $conf = $_[0] if $_[0];
    $conf;
}

sub _load_extensions {
    foreach ( findsubmod 'Mojolicious::Plugin::AttributeMaker::Extension' ) {
        load($_);
    }
}

sub _load_controllers {
    foreach ( findsubmod config()->{controllers} ) {
        load($_);    #Magic start here :)
    }
}

sub _is_loaded($) {
    my ($pkg) = @_;
    ( my $file = $pkg ) =~ s/::/\//g;
    $file .= '.pm';
    my @loaded = grep { $_ eq $file } keys %INC;
    if (@loaded) {
        return 1;
    }
    return;
}

sub make_attribute {
    my ( $package, $name, $cv ) = @_;
    my $config = config();
    if ( !exists $config->{attrs}->{$name} ) {
        print "Attribute ${name} registered!\n";
        $config->{attrs}->{$name} = $cv;
    }
    else {
        die("Attribute ${name} already registered!");
    }
}

sub register {
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};
    my $config = {
        base_controller => _is_loaded('Mojolicious::Lite')
        ? 'main'
        : 'Mojolicious::Controller',
        controllers => delete $conf->{controllers}
          || ( _is_loaded('Mojolicious::Lite') ? '' : die( __PACKAGE__ . " please set controller class" ) ),
        self      => $self,
        namespace => '',
        app       => $app,
        attrs     => {},
        %{$conf}
    };
    config($config);

    #Start infect
    no strict 'refs';
    *{ $config->{base_controller} . "::MODIFY_CODE_ATTRIBUTES" } = *MODIFY_CODE_ATTRIBUTES;
    *{ $config->{base_controller} . "::make_attribute" }         = *make_attribute;
    *Mojolicious::Plugin::AttributeMaker::Extension::make_attribute = *make_attribute;
    use strict 'refs';
    _load_extensions();
    _load_controllers() unless _is_loaded('Mojolicious::Lite');
}

=head1 AUTHOR

"Evgeniy Vansevich", C<< <"hammer at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-attributemaker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-AttributeMaker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::AttributeMaker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-AttributeMaker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-AttributeMaker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-AttributeMaker>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-AttributeMaker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 "Evgeniy Vansevich".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
