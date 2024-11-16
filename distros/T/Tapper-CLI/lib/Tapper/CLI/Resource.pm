package Tapper::CLI::Resource;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Resource::VERSION = '5.0.8';
use 5.010;
use warnings;
use strict;

use Text::Table;

sub resource_new
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'comment=s', 'active', 'help|?');
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Resource name missing!" unless $c->options->{name};
                say STDERR "$0 resource-new --name=s [ --comment=s ] [ --active ] [ --help ]";
                say STDERR "    --name      Name of the new resource";
                say STDERR "    --comment   Comment for the new resource";
                say STDERR "    --active    Make host active; without it resource will be initially deactivated";
                return;
        }

        require Tapper::Model;

        my $resource = {
                name => $c->options->{name},
                comment => $c->options->{comment},
                active => $c->options->{active} ? 1 : 0,
        };

        my $newresource = Tapper::Model::model('TestrunDB')->resultset('Resource')->create($resource);

        if($newresource) {
                say "Resource created.";
                return 0;
        } else {
                say STDERR "Error creating resource.";
                return 1;
        }
}

sub resource_update
{
        my ($c) = @_;
        $c->getopt( 'id|i=i', 'selectbyname=s', 'name|n=s', 'comment|c=s', 'active|a=i', 'help|?' );
        if ( $c->options->{help} or not defined $c->options->{id} and not defined $c->options->{selectbyname} ) {
                say STDERR "Resource name or id missing!" unless $c->options->{id} or $c->options->{selectbyname};
                say STDERR "$0 resource-update [ --id | --selectbyname ] [ --name=s ] [ --comment=s ] [ --active=i ] [ --help ]";
                say STDERR "    --id            Update resource with this id. Either this or selectbyname is required.";
                say STDERR "    --selectbyname  Update resource with this name. Either this or id is required.";
                say STDERR "    --name          New name for the resource";
                say STDERR "    --comment       New comment for the resource";
                say STDERR "    --active        Enable or disable resource";
                return;
        }

        require Tapper::Model;

        my $resource;
        if ( $c->options->{id} ) {
                $resource = Tapper::Model::model('TestrunDB')->resultset('Resource')->find($c->options->{id});
        } elsif ( $c->options->{selectbyname} ) {
                $resource = Tapper::Model::model('TestrunDB')->resultset('Resource')->search({
                        name => $c->options->{selectbyname},
                })->first;
        }

        unless (defined($resource))
          {
            say STDERR "Resource not found.";
            return 1;
          }

        $resource->name($c->options->{name}) if defined $c->options->{name};
        $resource->comment($c->options->{comment}) if defined $c->options->{comment};
        $resource->active($c->options->{active}) if defined $c->options->{active};

        $resource->update;

        say "Resource updated.";

        return 0;
}

sub resource_list {
        my ($c) = @_;
        $c->getopt( 'name=s@', 'id=i@', 'active', 'free', 'json', 'verbose|v', 'help|?' );
        if ( $c->options->{help} ) {
                say STDERR "$0 resource-list [ --name=s ... ] [ --id=i ... ] [ --free ] [ --active ] [ --verbose ] [ --help ]";
                say STDERR "    --id            Only show resources with this id. Can be specified multiple times";
                say STDERR "    --name          Only show resources with this name. Can be specified multiple times";
                say STDERR "    --active        Only show resources that are active";
                say STDERR "    --free          Only show resources that are free";
                say STDERR "    --verbose       Show extended information";
                say STDERR "    --json          Give results as json";
                say STDERR "    --help          Show this help";
                return;
        }

        require Tapper::Model;

        my $resources = Tapper::Model::model('TestrunDB')->resultset('Resource');

        if ($c->options->{name}) {
                $resources = $resources->search({ name => $c->options->{name} });
        }

        if ($c->options->{id}) {
                $resources = $resources->search({ id => $c->options->{id} });
        }

        if ($c->options->{active}) {
                $resources = $resources->search({ active => 1 });
        }

        if ($c->options->{free}) {
                $resources = $resources->search({ used_by_scheduling_id => undef });
        }

        my $table;
        my @entries = $resources->all;
        if ($c->options->{json}) {
                require JSON;

                my @json_resources;

                push @json_resources, {
                        id => $_->id,
                        name => $_->name,
                        comment => $_->comment,
                        active => $_->active ? \1 : \0,
                        in_use => (defined $_->used_by_scheduling_id) ? \1 : \0,
                } foreach (@entries);
                print JSON::encode_json(\@json_resources);

                return;
        } elsif ($c->options->{verbose}) {
                $table = Text::Table->new( "ID", "Name", "Comment", "Active", "Status" );


                my @table_data = map { [$_->id, $_->name, $_->comment, $_->active ? "Y" : "N",
                                        (defined $_->used_by_scheduling_id) ? "In Use" : "Free"] } @entries;

                $table->load(@table_data);
        } else {
                $table = Text::Table->new( "ID", "Name" );
                my @table_data =  map { [$_->id, $_->name] } @entries;
                $table->load(@table_data);
        }

        print $table;
        return;
}

sub setup
{
        my ($c) = @_;

        $c->register('resource-list', \&resource_list, 'List resources');
        $c->register('resource-new', \&resource_new, 'Create new resource');
        $c->register('resource-update', \&resource_update, 'Update resource');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Resource

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
