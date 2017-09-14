package RT::Extension::LifecycleUI;
use strict;
use warnings;
use Storable;

our $VERSION = '0.01';

RT->AddJavaScript("d3.min.js");
RT->AddJavaScript("handlebars-4.0.6.min.js");
RT->AddJavaScript("lifecycleui-model.js");
RT->AddJavaScript("lifecycleui-viewer.js");
RT->AddJavaScript("lifecycleui-viewer-interactive.js");
RT->AddJavaScript("lifecycleui-editor.js");

RT->AddStyleSheets("lifecycleui.css");
RT->AddStyleSheets("lifecycleui-viewer.css");
RT->AddStyleSheets("lifecycleui-viewer-interactive.css");
RT->AddStyleSheets("lifecycleui-editor.css");

$RT::Config::META{Lifecycles}{EditLink} = RT->Config->Get('WebURL') . 'Admin/Lifecycles/';
$RT::Config::META{Lifecycles}{EditLinkLabel} = "lifecycles administration";

sub _CloneLifecycleMaps {
    my $class = shift;
    my $maps  = shift;
    my $name  = shift;
    my $clone = shift;

    for my $key (keys %$maps) {
         my $map = $maps->{$key};

         next unless $key =~ s/^ \Q$clone\E \s+ -> \s+/$name -> /x
                  || $key =~ s/\s+ -> \s+ \Q$clone\E $/ -> $name/x;

         $maps->{$key} = Storable::dclone($map);
    }

    my $CloneObj = RT::Lifecycle->new;
    $CloneObj->Load($clone);

    my %map = map { $_ => $_ } $CloneObj->Valid;
    $maps->{"$name -> $clone"} = { %map };
    $maps->{"$clone -> $name"} = { %map };
}

sub _SaveLifecycles {
    my $class = shift;
    my $lifecycles = shift;
    my $CurrentUser = shift;

    my $setting = RT::DatabaseSetting->new($CurrentUser);
    $setting->Load('Lifecycles');
    if ($setting->Id) {
        if ($setting->Disabled) {
            my ($ok, $msg) = $setting->SetDisabled(0);
            return ($ok, $msg) if !$ok;
        }

        my ($ok, $msg) = $setting->SetContent($lifecycles);
        return ($ok, $msg) if !$ok;
    }
    else {
        my ($ok, $msg) = $setting->Create(
            Name    => 'Lifecycles',
            Content => $lifecycles,
        );
        return ($ok, $msg) if !$ok;
    }

    RT::Lifecycle->FillCache;

    return 1;
}

sub _CreateLifecycle {
    my $class = shift;
    my %args  = @_;
    my $CurrentUser = $args{CurrentUser};

    my $lifecycles = RT->Config->Get('Lifecycles');
    my $lifecycle;

    if ($args{Clone}) {
        $lifecycle = Storable::dclone($lifecycles->{ $args{Clone} });
        $class->_CloneLifecycleMaps(
            $lifecycles->{__maps__},
            $args{Name},
            $args{Clone},
        );
    }
    else {
        $lifecycle = { type => $args{Type} };
    }

    $lifecycles->{$args{Name}} = $lifecycle;

    my ($ok, $msg) = $class->_SaveLifecycles($lifecycles, $CurrentUser);
    return ($ok, $msg) if !$ok;

    return (1, $CurrentUser->loc("Lifecycle [_1] created", $args{Name}));
}

sub CreateLifecycle {
    my $class = shift;
    my %args = (
        CurrentUser => undef,
        Name        => undef,
        Type        => undef,
        Clone       => undef,
        @_,
    );

    my $CurrentUser = $args{CurrentUser};
    my $Name = $args{Name};
    my $Type = $args{Type};
    my $Clone = $args{Clone};

    return (0, $CurrentUser->loc("Lifecycle Name required"))
        unless length $Name;

    return (0, $CurrentUser->loc("Lifecycle Type required"))
        unless length $Type;

    return (0, $CurrentUser->loc("Invalid lifecycle type '[_1]'", $Type))
            unless $RT::Lifecycle::LIFECYCLES_TYPES{$Type};

    if (length $Clone) {
        return (0, $CurrentUser->loc("Invalid '[_1]' lifecycle '[_2]'", $Type, $Clone))
            unless grep { $_ eq $Clone } RT::Lifecycle->ListAll($Type);
    }

    return (0, $CurrentUser->loc("'[_1]' lifecycle '[_2]' already exists", $Type, $Name))
        if grep { $_ eq $Name } RT::Lifecycle->ListAll($Type);

    return $class->_CreateLifecycle(%args);
}

sub UpdateLifecycle {
    my $class = shift;
    my %args = (
        CurrentUser  => undef,
        LifecycleObj => undef,
        NewConfig    => undef,
        @_,
    );

    my $CurrentUser = $args{CurrentUser};
    my $name = $args{LifecycleObj}->Name;
    my $lifecycles = RT->Config->Get('Lifecycles');

    $lifecycles->{$name} = $args{NewConfig};

    my ($ok, $msg) = $class->_SaveLifecycles($lifecycles, $CurrentUser);
    return ($ok, $msg) if !$ok;

    return (1, $CurrentUser->loc("Lifecycle [_1] updated", $name));
}

sub UpdateMaps {
    my $class = shift;
    my %args = (
        CurrentUser  => undef,
        Maps         => undef,
        @_,
    );

    my $CurrentUser = $args{CurrentUser};
    my $lifecycles = RT->Config->Get('Lifecycles');

    %{ $lifecycles->{__maps__} } = (
        %{ $lifecycles->{__maps__} || {} },
        %{ $args{Maps} },
    );

    my ($ok, $msg) = $class->_SaveLifecycles($lifecycles, $CurrentUser);
    return ($ok, $msg) if !$ok;

    return (1, $CurrentUser->loc("Lifecycle mappings updated"));
}

=head1 NAME

RT-Extension-LifecycleUI - manage lifecycles via admin UI

=head1 INSTALLATION

=over

=item Install L<RT::Extension::ConfigInDatabase>

=item perl Makefile.PL

=item make

=item make install

This step may require root permissions.

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Plugin( "RT::Extension::LifecycleUI" );

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-LifecycleUI@rt.cpan.org|mailto:bug-RT-Extension-LifecycleUI@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-LifecycleUI>.

=head1 COPYRIGHT

This extension is Copyright (C) 2017 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
