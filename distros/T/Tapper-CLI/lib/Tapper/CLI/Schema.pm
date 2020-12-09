package Tapper::CLI::Schema;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Schema::VERSION = '5.0.7';
use 5.010;
use warnings;
use strict;


sub zipfiles
{
        my ($c) = @_;
        $c->getopt( 'quiet|q', 'help|?' );

        if ($c->options->{help} ) {
                say STDERR "Usage: $0 schema-zipfiles [ --quiet ]";
                say STDERR "\n  Optional arguments:";
                say STDERR "\t--quiet\tPrint a dot instead of the file name of the updated file";
                say STDERR "\t--help\t\tprint this help message and exit";
                exit -1;
        }

        require Compress::Bzip2;
        require Tapper::Model;
        my $uncompressed_files  = Tapper::Model::model('TestrunDB')->resultset('ReportFile')->search({is_compressed => 0});
        while (my $file = $uncompressed_files->next) {
                my $compressed;
                eval { $compressed = memBzip( $file->filecontent) };
                if (defined $compressed) {
                        print( $c->options->{quiet} ? '.' : "COMPRESS ".$file->report_id.":".$file->id.":".$file->filename."\n" );
                        $file->set_column(filecontent => $compressed);
                        $file->is_compressed(1);
                        $file->update();
                }
        }
}



sub setup
{
        my ($c) = @_;
        $c->register('schema-zipfiles', \&zipfiles, 'Compress all uncompressed files uploaded to reports framework');
        if ($c->can('group_commands')) {
                $c->group_commands('Schema commands', 'schema-zipfiles');
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Schema

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Schema;
    Tapper::CLI::Schema::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Schema - Tapper - handle everything related to schema changes

=head1 FUNCTIONS

=head2 zipfiles

Compress all uncompressed reportfile entries

@optparam quiet - be more chatty
@optparam help  - print out help message and die

=head2 setup

Initialize the notification functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
