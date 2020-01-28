package Tapper::CLI::Utils;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Utils::VERSION = '5.0.6';

use parent 'Exporter';
use Template;
use Tapper::Config;

use strict;
use warnings;

our @EXPORT_OK=qw(apply_macro gen_self_docu);



sub apply_macro
{
        my ($macro_text, $substitutes, $given_includes) = @_;

        my @standard_includes = (Tapper::Config->subconfig->{paths}{testplan_path}, '.');
        my $include_path_list = join ":", @standard_includes, @{$given_includes || []};

        my $tt            = Template->new({INCLUDE_PATH => $include_path_list, ABSOLUTE => 1});
        my $ttapplied;

        if ($macro_text =~ /\n/ or not -e $macro_text) {
                $tt->process(\$macro_text, $substitutes, \$ttapplied) or die $tt->error();
        } else {
                $tt->process($macro_text, $substitutes, \$ttapplied) or die $tt->error();
        }

        return $ttapplied;
}


sub gen_self_docu
{
        my ($text) = @_;
        my @guide = grep { m/^###/ } split (qr/\n/, $text);
        my $self_docu = "Self-documentation:\n";
        $self_docu.= join "\n", map { my $l = $_; $l =~ s/^###/ /; "$l\n" } @guide;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Utils

=head2 apply_macro

Process macros and substitute using Template::Toolkit.

@param string  - text or filename containing macros
@param hashref - containing substitutions
@optparam array ref - path to more include files

@return success - text with applied macros
@return error   - die with error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
