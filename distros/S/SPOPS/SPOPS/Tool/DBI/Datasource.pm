package SPOPS::Tool::DBI::Datasource;

# $Id: Datasource.pm,v 3.5 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory qw( ERROR OK NOTIFY );

my $log = get_logger();

$SPOPS::Tool::DBI::Datasource::VERSION = sprintf("%d.%02d", q$Revision: 3.5 $ =~ /(\d+)\.(\d+)/);

sub behavior_factory {
    my ( $class ) = @_;
    $log->is_info &&
        $log->info( "Installing datasource configuration for ($class)" );
    return { manipulate_configuration => \&datasource_access };
}

my $generic_ds_sub = <<'DS';

sub %%CLASS%%::global_datasource_handle {
    my ( $class ) = @_;
    unless ( $%%CLASS%%::DBH ) {
        require DBI;
        $%%CLASS%%::DBH = DBI->connect( '%%DSN%%', '%%USER%%', '%%PASS%%' )
                               || SPOPS::Exception->throw(
                                      "Cannot connect to database for [%%CLASS%%]: $DBI::errstr" );
        $%%CLASS%%::DBH->{RaiseError} = 1;
        $%%CLASS%%::DBH->{PrintError} = 0;
        $%%CLASS%%::DBH->{ChopBlanks} = 1;
        $%%CLASS%%::DBH->{AutoCommit} = 1;
        $%%CLASS%%::DBH->trace( %%TRACE%% );
    }
    return $%%CLASS%%::DBH;
}
DS

sub datasource_access {
    my ( $class ) = @_;
    my $dbi_config = $class->CONFIG->{dbi_config};
    unless ( ref $dbi_config eq 'HASH' and
             $dbi_config->{dsn} ) {
      return ( NOTIFY, "Cannot create datasource access subroutine for " .
                       "[$class] because you do not have " .
                       "'dbi_config->dsn' defined" );
    }

    my $trace_level = $dbi_config->{trace} || 0;
    my $ds_code = $generic_ds_sub;
    $ds_code =~ s/%%CLASS%%/$class/g;
    $ds_code =~ s/%%DSN%%/$dbi_config->{dsn}/g;
    $ds_code =~ s/%%USER%%/$dbi_config->{username}/g;
    $ds_code =~ s/%%PASS%%/$dbi_config->{password}/g;
    $ds_code =~ s/%%TRACE%%/$trace_level/g;
    {
        local $SIG{__WARN__} = sub { return undef };
        eval $ds_code;
    }
    if ( $@ ) {
        warn "Code: $ds_code\n";
        return ( ERROR, "Cannot create 'global_datasource_handle() for ($class): $@" );
    }
    return ( OK, undef );
}

1;

__END__

=head1 NAME

SPOPS::Tool::DBI::Datasource -- Embed the parameters for a DBI handle in object configuration

=head1 SYNOPSIS

 my $spops = {
   myobject => {
     class      => 'My::Object',
     rules_from => [ 'SPOPS::Tool::DBI::Datasource' ],
     dbi_config => { dsn => 'DBI:mysql:test',
                     username => 'kool',
                     password => 'andthegang' },
     ...
   },
 };
 SPOPS::Initialize->process({ config => $spops });
 my $object = My::Object->fetch( 'celebrate' );

=head1 DESCRIPTION

This rule allows you to embed the DBI connection information in your
object rather than using the strategies described elsewhere. This is
very handy for creating simple, one-off scripts, but you should still
use the subclassing strategy from
L<SPOPS::Manual::Cookbook|SPOPS::Manual::Cookbook> if you will have
multiple objects using the same datasource.

You can specify the following items in the configuration:

=over 4

=item *

C<dsn>: The DBI DSN, or the first entry in the normal DBI C<connect> call.

=item *

C<username>: Username to connect with

=item *

C<password>: Password to connect with

=item *

C<trace>: Trace level to use (0-5, see L<DBI|DBI> for what the levels
mean)

=back

=head1 METHODS

B<behavior_factory( $class )>

Generates a behavior to generate the datasource retrieval code during
the 'manipulate_configuration' phase.

B<datasource_access( $class )>

Generates the 'global_datasource_handle()' method that retrieves an
opened database handle if it exists or creates one otherwise.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Manual::CodeGeneration|SPOPS::Manual::CodeGeneration>

L<SPOPS::DBI|SPOPS::DBI>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

Thanks to jeffa on PerlMonks
(http://www.perlmonks.org/index.pl?node_id=18800) for suggesting this!
