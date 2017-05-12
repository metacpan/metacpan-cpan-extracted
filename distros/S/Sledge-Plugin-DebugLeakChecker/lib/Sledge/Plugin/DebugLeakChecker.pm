package Sledge::Plugin::DebugLeakChecker;

use strict;
use warnings;
our $VERSION = '0.01';

use Template;
use Devel::Leak::Object qw{ GLOBAL_bless };

our $FIREBUG = 0;
our $TEMPLATE = <<'EOF';
[%- IF FIREBUG %]
<script type="text/javascript">
console.log('Leak Modules');
[%- FOR e IN devel_leak_object_count_entries %]
console.log('[% e.key %] : [% e.value %] leak[% IF e.value > 1 %]s[% END # END IF %]');
[% END # END FOR -%]
</script>
[% ELSE %]
    <div style="background-color:#fff;border:1px solid #069;text-align:left;left-margin:3px">
        <div style="padding:8px; font-size:140%; font-weight:bold; background-color:#069; color:#FFF">Leak Modules</div>
        <table style="color:#069;text-align:center" width="100%">
            <tr style="background-color:#DDD"><th style="padding:5px" width="70%">Module Name</th><th style="padding:5px" width="30%">Leak Count</th></tr>
            [%- FOR e IN devel_leak_object_count_entries %]
            <tr style="text-align:left;[% IF loop.count % 2 == 0 && !loop.first %] background-color:#DDD[% END # END IF %]"><th style="padding:5px;text-align:left;"><a href="http://search.cpan.org/perldoc?[% e.key | html %]" target="_blank">[% e.key | html %]</th><td style="[% IF e.value > 100 %]color:red;[% END # END IF %] font-weight:bold;text-align:center;padding:5px;">[% e.value | html %]</td></tr>
            [% END # END FOR -%]
        </table>
    </div>
[% END # END IF -%]
</body>
EOF

sub import {
    my $class = shift;
    my @args = @_;
    my $pkg   = caller;

    foreach my $arg (@args) {
        if(uc($arg) eq 'FIREBUG') {
            $FIREBUG = 1;
        }
    }

    $pkg->register_hook(BEFORE_OUTPUT => sub {
        my $self = shift;
        if ($self->debug_level) {
            $self->add_filter(sub {
                $class->_debug_message_filter(@_);
            });
        }
    });

}

sub _debug_message_filter {
    my ($self, $pages, $content) = @_;

    my %devel_leak_object_count_entries;
    for (sort keys %Devel::Leak::Object::OBJECT_COUNT) {
        next unless $Devel::Leak::Object::OBJECT_COUNT{$_}; # Don't list class with count zero
        $devel_leak_object_count_entries{ sprintf( "%-40s",$_) } = $Devel::Leak::Object::OBJECT_COUNT{$_};
    }

    my $tt = Template->new;
    $tt->process(
          \$TEMPLATE,
         {
            devel_leak_object_count_entries => \%devel_leak_object_count_entries,
            FIREBUG => $FIREBUG
         },
    \my $out);

    if( $content =~ /<\/body>/ ) {
        $content =~ s/<\/body>/$out/;
    } else {
        $out =~ s/<\/body>//;
        $content .= $out;
    }
    return $content;
}

1;

=head1 NAME

Sledge::Plugin::DebugLeakChecker - Show the memory leak situation of perl modules for Sledge


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

=head2 Apache setting

At first, write this in the startup.pl

    BEGIN {
        use Devel::Leak::Object qw{ GLOBAL_bless };
    }

Example of httpd.conf when I debug it.

    MinSpareServers      1
    MaxSpareServers      1
    StartServers         1
    MaxRequestsPerChild  0


=head2 Sledge Pages Class setting

B<Default setting>

Information is added to the lower part of Web pages displaying now.

    use Sledge::Plugin::BeforeOutput;
    use Sledge::Plugin::DebugLeakChecker;
    
    ...

B<Output to Firebug>

It is necessary to install Firebug beforehand.

Information is output by console of the Firebug.

    use Sledge::Plugin::BeforeOutput;
    use Sledge::Plugin::DebugLeakChecker qw(Firebug);
    
    ...


=head1 DESCRIPTION

This module provides information that is leak situation of perl modules.

When you use mod_perl with Apache, I think it to be able to get particularly effective information.


=head1 SEE ALSO

L<Devel::Leak::Object> L<Sledge::Plugin::BeforeOutput>

Firebug Firefox Add-ons
L<https://addons.mozilla.org/ja/firefox/addon/1843>

Firebug Lite for IE, Opera and Safari
L<http://getfirebug.com/lite.html>

=head1 BUGS

Please report any bugs or suggestions at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-DebugLeakChecker>


=head1 AUTHOR

syushi matsumoto, C<< <matsumoto at alink.co.jp> >>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Alink INC. all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

