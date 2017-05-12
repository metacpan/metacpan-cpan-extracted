package OAuthomatic::ServerDef;
# ABSTRACT: Predefined URLs for some services

use strict;
use warnings;
use feature 'state';
use namespace::sweep;


use Exporter::Shiny qw/oauthomatic_predefined_list
                       oauthomatic_predefined_for_name/;

use Try::Tiny;
use Scalar::Util qw/blessed reftype/;
use Module::Pluggable
  require => 1,    # Just warns, so let's keep it
  search_path => ["OAuthomatic::ServerDef"],
  sub_name => '_oauthomatic_predefined_list';


sub _calculate_predefined {
    my %predefined;
    foreach my $predef_module (_oauthomatic_predefined_list()) {
        unless($predef_module =~ /^OAuthomatic::ServerDef::(.*)$/x) {
            # This should never happen, but let's just ignore
            warn "OAuthomatic predef: skipping incorrect module $predef_module\n";
            next;
        }
        my $short_module_name = $1;

        my $predef;
        unless($predef_module->can('server')) {
            warn "OAuthomatic predef: bad plugin, module $predef_module does not contain server() function\n";
            next;
        }
        try {
            $predef = $predef_module->server();
        } catch {
            warn "OAuthomatic predef: bad plugin, function $predef_module" . "::server() failed: $_\n";
        };
        next unless $predef;
        my $predef_type = blessed $predef;
        unless( $predef_type eq 'OAuthomatic::Server' ) {
            $predef_type ||= reftype \$predef;
            warn "OAuthomatic predef: bad plugin, function $predef_module" . "::server() returned invalid value (expected object of type OAuthomatic::Server, got $predef_type)\n";
            next;
        }
        my $site_name = $predef->site_name;
        unless($site_name eq $short_module_name) {
            warn "OAuthomatic predef: bad plugin, $predef_module provided object with bad site_name (got '$site_name', expected '$short_module_name' - matching module name)\n";
            next;
        }
        $predefined{ $site_name } = $predef;
    }
    return \%predefined;
}

sub _predefined {
    state $predefined = _calculate_predefined();
    return $predefined;
}


sub oauthomatic_predefined_list {
    my $predefined = _predefined();
    return values %$predefined;
}


sub oauthomatic_predefined_for_name {
    my $name = shift;
    my $predefined = _predefined();
    if( exists $predefined->{$name} ) {
        return $predefined->{$name};
    }
    return OAuthomatic::Error::Generic->throw(
       ident => "No such predefined server: $name",
       extra => "Currently known servers: "
         . join(", ", sort keys %$predefined)
         . "\n"
         . "Maybe you should install OAuthomatic::ServerDef::$name?\n",
      );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::ServerDef - Predefined URLs for some services

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Manages list of definitions of selected OAuth endpoints.  This module
is mostly used internally, whenever someone writes:

     OAuthomatic->new(
         server => 'SomeName',
     );

it is used to look up appropriate definition.

Run script L<oauthomatic_predefined_servers> to list all currently
known endpoints.

To add server to the list, define module named
C<OAuthomatic::ServerDef::ServerName>:

    package OAuthomatic::ServerDef::ServerName;
    use strict;
    use warnings;
    use OAuthomatic::Server;

    sub server {
        return OAuthomatic::Server->new(
            site_name => 'ServerName',   # Must match package name
            oauth_temporary_url => 'https://...',
            # ... And the rest
        );
    }
    1;

=head1 EXPORTS FUNCTIONS

=head2 oauthomatic_predefined_list

Returns list of all predefined servers (list of L<OAuthomatic::Server> objects).

=head2 oauthomatic_predefined_for_name(ServerName)

Returns predefined object for given name, or dies.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
