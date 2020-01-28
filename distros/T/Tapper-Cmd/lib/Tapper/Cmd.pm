package Tapper::Cmd;
# git description: v5.0.10-1-g39d0b86

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Backend functions for CLI and Web
$Tapper::Cmd::VERSION = '5.0.11';
use Moose;

extends 'Tapper::Base';

use Tapper::Model 'model';
use File::Slurp;

has schema => (
        is      => 'rw',
        isa     => 'Tapper::Schema::TestrunDB',
        default => sub { return model('TestrunDB') },
);



sub assign_preconditions
{
        my ($self, $testrun_id, @preconditions) = @_;
        my $testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        return $testrun->assign_preconditions(@preconditions);

}


# This apply_macro function allows access to reportdata and dpath. Thats
# why it uses Tapper::Reports::DPath::TT instead of Template
# directly. Thats because that way we can make testplans dependent on
# former reports without doing it right.
sub apply_macro
{
        my ($self, $file, $substitutes, $includes) = @_;

        $substitutes ||= {};
        my $plan = File::Slurp::slurp($file);

        require Tapper::Config;
        my @include_paths = (Tapper::Config->subconfig->{paths}{testplan_path},
                             Tapper::Config->subconfig->{paths}{use_case_path});
        push @include_paths, @{$includes || [] };
        my $include_path_list = join ":", @include_paths;
        require Tapper::Reports::DPath::TT;
        my $tt = Tapper::Reports::DPath::TT->new(include_path => $include_path_list,
                                                 substitutes  => $substitutes,
                                                );
        return $tt->render_template($plan);
}


1; # End of Tapper::Cmd

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd - Tapper - Backend functions for CLI and Web

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module is the base module that
contains common functions of all modules in the project. No such functions
exist yet.

    use Tapper::Cmd::Testrun;
    use Tapper::Cmd::Precondition;

    my $foo = Tapper::Cmd::Precondition->new();
    $foo->add($precondition);

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS

=head2 assign_preconditions

Assign a list of preconditions to a testrun. Both have to be given as valid
ids.

@param int - testrun id
@param array of int - precondition ids

@return success - 0
@return error   - error string

=head2 apply_macro

Process macros and substitute using Template::Toolkit. This function
allows to access reportdata and use dpath in testplans.

@param string  - file name
@param hashref - containing substitutions
@optparam string - path to more include files

@return success - text with applied macros
@return error   - die with error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
