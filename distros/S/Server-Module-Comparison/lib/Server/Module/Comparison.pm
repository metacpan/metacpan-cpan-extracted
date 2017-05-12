use strictures 2;
package Server::Module::Comparison;

# ABSTRACT: check perl module versions installed on servers.

use Path::Tiny;
use Moo;
use Types::Standard -types;
use Capture::Tiny qw/capture/;
use failures qw/module::comparison/;
use Perl::Version;

our $VERSION = '0.012';

has perl_path => (is => 'ro', isa => Str, default => '');
has modules => (is => 'ro', isa => ArrayRef);

sub FromModuleList
{
    my $filename = shift;
    my $extra_params = shift;
    $extra_params = {} unless defined $extra_params;
    my @lines;
    if($filename eq '-')
    {
        @lines = <STDIN>;
    }
    else
    {
        @lines = path($filename)->lines_utf8;
    }
    my @modules = map { chomp; $_ } grep { !/^\s*$/ }  @lines;
    return Server::Module::Comparison->new({ %$extra_params, modules => \@modules });
}

sub _mversion_command
{
    my $self = shift;
    my $command = 'mversion';
    if($self->perl_path)
    {
        $command = path($self->perl_path)->child($command);
    }
    return [$command, '-f', @{$self->modules}, '2>&1'];
}

sub check_container
{
    my $self = shift;
    my $container = shift;
    my $cmd = [qw/docker run --rm -i/, $container, @{$self->_mversion_command}];
    return $self->_run_mversion($cmd);
}

sub check_ssh_server
{
    my $self = shift;
    my $server = shift;
    my $cmd = ['ssh', $server, @{$self->_mversion_command}];
    return $self->_run_mversion($cmd);
}

sub check_local
{
    my $self = shift;
    my $cmd = $self->_mversion_command;
    return $self->_run_mversion($cmd);
}

sub identify_resource
{
    my $self = shift;
    my $identifier = shift;
    if($identifier =~ m|docker://(.*)$|)
    {
        return ('docker', $1);
    }
    elsif($identifier =~ m|ssh://(.*)$|)
    {
        return ('ssh', $1);
    }
    elsif($identifier =~ m|/|)
    {
        # assume it's docker
        return ('docker', $identifier);
    }
    else
    {
        # assume it's ssh
        return ('ssh', $identifier);
    }
}

sub check_correct_guess
{
    my $self = shift;
    my $identifier = shift;
    my ($type, $server) = $self->identify_resource($identifier);
    if($type eq 'ssh')
    {
        return $self->check_ssh_server($server);
    }
    elsif($type eq 'docker')
    {
        return $self->check_container($server);
    }
    else
    {
        die 'I don\'t know what to do!';
    }
}

sub _run_mversion
{
    my $self = shift;
    my $cmd = shift;
    #print "$cmd\n";
    my ($stdout, $stderr, $exit) = capture {
        system(@$cmd);
    };
    if($exit)
    {
        my $command = join(' ', @$cmd);
        failure::module::comparison->throw("Failure running $command: $exit");
    }
    my @lines = map { chomp; $_ } grep { !/^\s*$/ } split(/\r\n|\r|\n/, $stdout);
    my %versions = map { _module_pair($_) } @lines;
    return \%versions;
}

sub _module_pair
{
    my $line = shift;
    my ($module, $version) = $line =~ /(.*) ((:?\d+(:?\.\d+)*|undef))/;
    if($module)
    {
        return ($module, $version);
    }
    else
    {
        my ($missing_module) = $line =~ /'(.*)' does not seem/;
        unless($missing_module)
        {
            print "Error: $line\n";
            return ("error", "error");
        }
        return ($missing_module, 'missing');
    }
}

sub _wrap_version
{
    my $version = shift;
    if($version && ($version eq 'undef' || $version eq 'missing'))
    {
        # this isn't perfect, in fact it may bite us.
        # I believe that undef does indicate that a module is
        # there, it's just it doesn't have $VERSION set.
        return Perl::Version->new('0');
    }
    return Perl::Version->new($version);
}

sub difference_report
{
    my $self = shift;
    my $first = shift;
    my $second = shift;

    my %newer;
    my %older;
    my %newly_installed;
    my %removed;
    for my $module (keys %$first)
    {
        if(exists $second->{$module})
        {
            my $v1 = _wrap_version($first->{$module});
            my $v2 = _wrap_version($second->{$module});
            if($v1 > $v2)
            {
                $older{$module} = [$first->{$module}, $second->{$module}];
            }
            elsif($v1 < $v2)
            {
                $newer{$module} = [$first->{$module}, $second->{$module}];
            }
        }
        else
        {
            $removed{$module} = $first->{$module};
        }
    }
    for my $module (keys %$second)
    {
        unless(exists $first->{$module})
        {
            $newly_installed{$module} = $second->{$module};
        }
    }
    return {
        updated => \%newer,
        downgraded => \%older,
        removed => \%removed,
        installed => \%newly_installed,
    };
}

sub human_readable_report
{
	my $self = shift;
    my $report = shift;
    my @lines;
    if(%{$report->{downgraded}})
    {
        push @lines, 'DOWNGRADED Modules', '';
        for my $key (sort keys %{$report->{downgraded}}) 
        {
            my ($v1, $v2) = @{$report->{downgraded}->{$key}};
            push @lines, sprintf("%-40s\t%s -> %s", $key, $v1, $v2);
        }
        push @lines, '';
    }
    if(%{$report->{removed}})
    {
        push @lines, 'REMOVED Modules', '';
        for my $key (sort keys %{$report->{removed}}) 
        {
            my $v1 = $report->{removed}->{$key};
            push @lines, sprintf("%-40s\t%s", $key, $v1);
        }
        push @lines, '';
    }
    if(%{$report->{installed}})
    {
        push @lines, 'Installed Modules', '';
        for my $key (sort keys %{$report->{installed}}) 
        {
            my $v1 = $report->{installed}->{$key};
            push @lines, sprintf("%-40s\t%s", $key, $v1);
        }
        push @lines, '';
    }
    if(%{$report->{updated}})
    {
        push @lines, 'Updated Modules', '';
        for my $key (sort keys %{$report->{updated}}) 
        {
            my ($v1, $v2) = @{$report->{updated}->{$key}};
            push @lines, sprintf("%-40s\t%s -> %s", $key, $v1, $v2);
        }
        push @lines, '';
    }
    unless(@lines)
    {
        push @lines, 'No differences', '';
    }
	return join "\n", @lines;
}

sub human_readable_list
{
    my $self = shift;
    my $list = shift;

    my @lines;
    for my $module (keys %$list)
    {
        push @lines, sprintf("%-40s\t%s", $module, $list->{$module});
    }
    return join "\n", @lines;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Server::Module::Comparison - check perl module versions installed on servers.

=head1 VERSION

version 0.012

=head1 SYNOPSIS

Gets versions of perl modules on servers.

    my $comparer = Server::Module::Comparison->new({
         perl_path => '/opt/perl5/bin',
         modules => [qw/OpusVL::CMS OpusVL::FB11X::CMSView OpusVL::FB11X::CMS/]
     });
    my $versions = $comparer->check_container('quay.io/opusvl/prem-website:staging');


    my $comparer = Server::Module::Comparison::FromModuleList(
        'modules.txt',
        { perl_path => '/opt/perl5/bin/' }
    );

=head1 DESCRIPTION

A module for checking which versions of a particular list of perl modules
are installed on a server.

This relies on C<mversion> (L<Module::Version>) being installed on the server
to make querying the module version numbers simple.

This module uses system and isn't expected to defend against malicous input
at all.  It is designed as a quick and simple developer tool.

=head1 METHODS

=head2 FromModuleList

Createa a new Server::Module::Comparison object from a line delimited list of
modules.

=head2 check_container

Run mversion in a docker container.

    my $versions = $comparer->check_container('quay.io/user/some-website:staging');

This is done by running the container locally.  It does not try to pull the
container.  It is assumed you have access to docker and the correct image to hand.

=head2 check_ssh_server

Checks modules via ssh.

=head2 check_local

Checks modules locally.

=head2 check_correct_guess

This takes a string and guesses whether to assume it's a container identifier
or an ssh server.

Also supports a C<docker://> or C<ssh://> type uri scheme to help identify
the server being identified.

=head1 ATTRIBUTES

=head2 perl_path

Location of perl (and therefore also where mversion will be installed).
Set this if you have your perl installed in a non default location not
on the path.  We have ours installed to C</opt/perl5/bin> for example.

=head2 modules

The list of modules to check.  This is an array ref.

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
