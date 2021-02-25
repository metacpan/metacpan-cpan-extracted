package OTRS::OPM::Validate;
$OTRS::OPM::Validate::VERSION = '0.04';
# ABSTRACT: Validate .opm files

use v5.20;

use strict;
use warnings;

my %boundaries = (
    # tag             min max
    CVS          => [ 0,   1],
    Name         => [ 1,   1],
    URL          => [ 1,   1],
    Vendor       => [ 1,   1],
    Version      => [ 1,   1],
    BuildDate    => [ 0,   1],
    BuildHost    => [ 0,   1],
);

sub validate {
    my ($class, $content) = @_;

    $content =~ s{
      <!-- .*? -->
    }{}xmsg;

    my ($check,$grammar) = _grammar( $content );
    my $match = $content =~ $grammar;
    die 'Invalid .opm file' if !$match;

    for my $key ( keys %boundaries ) {
        $check->( $key );
    }
}

sub _grammar {
    my ($content) = @_;

    my %s;

    my $check = sub {
        my ($name, $max, $min) = @_;

        $max //= (exists $boundaries{$name} ? $boundaries{$name}->[-1] : 100_000);
        $min //= (exists $boundaries{$name} ? $boundaries{$name}->[0] : 0);

        $s{$name} //= 0;

        my $context = '';
#        my $pos     = pos();
#        if ( $pos ) {
#            my $start_length = 30;
#            my $start        = $pos - $start_length;
#            if ( $start < 0 ) {
#                $start_length = $pos;
#                $start        = 0;
#            }
#
#            my $end_length = 30;
#            if ( $pos + $end_length > length $content ) {
#                $end_length = ( length $content ) - $pos;
#            }
#
#            $context = sprintf "\n%s <-- --> %s",
#                ( substr $content, $start, $start_length ),
#                ( substr $content, $pos, $end_length );
#        }

        if ( $s{$name} > $max ) {
            die sprintf 'Too many "%s" elements. Max %s element(s) allowed.%s', $name, $max, $context;
        }
        elsif ( $s{$name} < $min ) {
            die sprintf 'Too few "%s" elements. Min %s element(s) required.%s', $name, $min, $context;
        }
    };

    my $grammar = qr{
       \A(?&PACKAGE)\z

       (?(DEFINE)
           (?<PACKAGE>
               \s* <\?xml \s* version="1.0" \s* encoding="[^"]+?" \s* \?> \s+
               \s* <(?<product>otrs|otobo)_package \s+ version="[12].[0-9]+">
               (?:\s*(?&PACKAGE_TAGS))+
               \s* </\g{product}_package> \s*
           )

           (?<PACKAGE_TAGS>
               (?:<CVS>.*?</CVS>(?{$s{CVS}++; $check->('CVS')})) |
               (?:<Name>.*?</Name>(?{++$s{Name}; $check->('Name')})) |
               (?:<Version>.*?</Version>(?{++$s{Version}; $check->('Version')})) |
               (?:<Vendor>.*?</Vendor>(?{++$s{Vendor}; $check->('Vendor')})) |
               (?:<URL>.*?</URL>(?{++$s{URL}; $check->('URL')})) |
               (?:<License>.*?</License>(?{++$s{License}; $check->('License')})) |
               (?:<BuildDate>.*?</BuildDate>(?{$s{BuildDate}++; $check->('BuildDate')})) |
               (?:<BuildHost>.*?</BuildHost>(?{$s{BuildHost}++; $check->('BuildHost')})) |
               (?:<OS>.*?</OS>) |
               (?&FRAMEWORK) |
               (?&DESCRIPTION) |
               (?&INTRO) |
               (?&CODE) |
               (?&PACKAGEMERGE) |
               (?&PREREQ) |
               (?&FILELIST) |
               (?&DATABASE) |
               (?&CHANGELOG)
           )

           (?<FRAMEWORK>
               <Framework (?{delete @s{'Framework.Min','Framework.Max'}}) ( \s+ (?&FRAMEWORK_ATTR))*>.*?</Framework>
           )

           (?<FRAMEWORK_ATTR>
               (?:Maximum=".*?"(?{++$s{'Framework.Max'}; $check->('Framework.Max',1)})) |
               (?:Minimum=".*?"(?{++$s{'Framework.Min'}; $check->('Framework.Min',1)}))
           )

           (?<DESCRIPTION>
               <Description (?{delete $s{'Description.Lang'}}) ( \s+ (?&DESCRIPTION_ATTR))*>.*?</Description>
           )

           (?<DESCRIPTION_ATTR>
               (?:Lang="(?<lang>[a-zA-Z]+)"(?{++$s{'Description.Lang'}; $check->('Description.Lang',1)})) |
               (?:Format="[a-zA-Z]+"(?{++$s{'Description.Format'}; $check->('Description.Format',1)})) |
               (?:Translatable="[01]"(?{++$s{'Description.Translatable'}; $check->('Description.Translatable',1)}))
           )

           (?<CHANGELOG>
               <ChangeLog (?{delete $s{'ChangeLog.Date'}; delete $s{'ChangeLog.Version'}; })
                   ( \s+ (?&CHANGELOG_ATTR))+>.*?
               </ChangeLog> (?{$check->('ChangeLog.Date', 1, 1); $check->('ChangeLog.Version', 1, 1); })
           )

           (?<CHANGELOG_ATTR>
               (?:Date=".*?"(?{++$s{'ChangeLog.Date'}; $check->('ChangeLog.Date',1,1)})) |
               (?:Version=".*?"(?{++$s{'ChangeLog.Version'}; $check->('ChangeLog.Version',1,1)}))
           )

           (?<INTRO>
               <Intro(?<intro_type>Install|Upgrade|Reinstall|Uninstall) (?{delete @s{map{'Intro.'. $_}qw/Type Lang Title Translatable Version Format/};})
                   ( \s+ (?&INTRO_ATTR))+>.*?
               </Intro\g{intro_type}> (?{$check->('Intro.Type', 1, 1);})
           )

           (?<INTRO_ATTR>
               (?:Type="(?i:Post|Pre)"(?{++$s{'Intro.Type'}; $check->('Intro.Type',1,1)})) |
               (?:Title=".*?"(?{++$s{'Intro.Title'}; $check->('Intro.Title',1)})) |
               (?:Format=".*?"(?{++$s{'Intro.Format'}; $check->('Intro.Format',1)})) |
               (?:Lang="[A-Za-z]+"(?{++$s{'Intro.Lang'}; $check->('Intro.Lang',1)})) |
               (?:Translatable="[01]"(?{++$s{'Intro.Translatable'}; $check->('Intro.Translatable',1)})) |
               (?:Version=".*?"(?{++$s{'Intro.Version'}; $check->('Intro.Version',$+{intro_type} eq 'Upgrade' ? 1 : 0)}))
           )
     
           (?<CODE>
               <Code(?<code_type>Install|Upgrade|Reinstall|Uninstall) (?{delete @s{map{'Code.'. $_}qw/Type Version/};})
                   ( \s+ (?&CODE_ATTR))+>.*?
               </Code\g{code_type}> (?{$check->('Code.Type', 1, 1);})
           )

           (?<CODE_ATTR>
               (?:Type="(?i:Post|Pre)"(?{++$s{'Code.Type'}; $check->('Code.Type',1,1)})) |
               (?:Version=".*?"(?{++$s{'Code.Version'}; $check->('Code.Version',$+{code_type} eq 'Upgrade' ? 1 : 0)}))
           )

           (?<PREREQ>
               <(?<prereq_type>Module|Package)Required (?{delete $s{'Prereq.Version'};})
                 (\s+ (?&VERSION))?>.*?
               </\g{prereq_type}Required> (?{$check->('Prereq.Version', 1);})
           )

           (?<VERSION>
               (?:Version=".*?"(?{++$s{'Prereq.Version'}; $check->('Prereq.Version', 1)}))
           )

           (?<PACKAGEMERGE>
               <PackageMerge (?{delete $s{'Merge.Name'};})
                 (\s+ (?&PACKAGEMERGEATTR))+>.*?
               </PackageMerge> (?{$check->('Merge.Name', 1, 1);})
           )

           (?<PACKAGEMERGEATTR>
               (?:TargetVersion=".*?"(?{++$s{'Merge.Version'}; $check->('Merge.Version', 1)})) |
               (?:Name=".*?"(?{++$s{'Merge.Name'};}))
           )


           (?<FILELIST>
               <Filelist>(\s*(?&FILE))+\s*</Filelist>
           )

           (?<FILE>
               <File (?{delete @s{map{'File.'. $_}qw/Location Permission Encode/};})
                   ( \s+ (?&FILE_ATTR))+>.*?
               </File> (?{$check->('File.' . $_ , 1, 1) for qw/Location Permission Encode/;})
           )

           (?<FILE_ATTR>
               (?:Location=".*?"(?{++$s{'File.Location'};})) |
               (?:Encode=".*?"(?{++$s{'File.Encode'};})) |
               (?:Permission=".*?"(?{++$s{'File.Permission'};}))
           )

           (?<DATABASE>
               <Database(?<database_type>Install|Upgrade|Reinstall|Uninstall) (?{delete @s{map{'Database.'. $_}qw/Type Version/};})
                   ( \s+ (?&DATABASE_ATTR)){0,3}>
                   (\s* (?&DATABASE_TAGS) )+ \s*
               </Database\g{database_type}>
           )

           (?<DATABASE_ATTR>
               (?:Type="(?i:Post|Pre)"(?{++$s{'Database.Type'}; $check->('Database.Type',1)})) |
               (?:Version=".*?"(?{++$s{'Database.Version'}; $check->('Database.Version',$+{database_type} eq 'Upgrade' ? 1 : 0)}))
           )

           (?<DATABASE_TAGS>
               (?&TABLE_CREATE) |
               (?&TABLE_DROP) |
               (?&TABLE_ALTER) |
               (?&INSERT)
           )

           (?<TABLE_CREATE>
               <TableCreate (?{delete @s{map{'Table.'. $_}qw/Name Type Version/};})
                   ( \s+ (?&TABLE_ATTR))+>
                   (\s* (?&TABLE_CREATE_TAGS) )+ \s*
               </TableCreate>
           )

           (?<TABLE_CREATE_TAGS>
               (?&COLUMN) |
               (?&FOREIGN_KEY) |
               (?&INDEX) |
               (?&UNIQUE)
           )

           (?<TABLE_ALTER>
               <TableAlter (?{delete @s{map{'Table.'. $_}qw/Name Type Version/};})
                   ( \s+ (?&TABLE_ATTR))+>
                   (\s* (?&TABLE_ALTER_TAGS) )+ \s*
               </TableAlter>
           )

           (?<TABLE_ALTER_TAGS>
               (?&COLUMN_ADD) |
               (?&COLUMN_DROP) |
               (?&COLUMN_CHANGE) |
               (?&FOREIGN_KEY_CREATE) |
               (?&FOREIGN_KEY_DROP) |
               (?&INDEX_CREATE) |
               (?&INDEX_DROP) |
               (?&UNIQUE_CREATE) |
               (?&UNIQUE_DROP)
           )

           (?<TABLE_DROP>
               <TableDrop (?{delete @s{map{'Table.'. $_}qw/Name Type Version/};})
                   ( \s+ (?&TABLE_ATTR))+ (?:/>|>\s*</TableDrop>)
           )

           (?<TABLE_ATTR>
               (?:Name=".*?"(?{++$s{'Table.Name'}; $check->('Table.Name',1,1)})) |
               (?:Type="(?i:Post|Pre)"(?{++$s{'Table.Type'}; $check->('Table.Type',1)})) |
               (?:Version=".*?"(?{++$s{'Table.Version'}; $check->('Table.Version',$+{database_type} eq 'Upgrade' ? 1 : 0)}))
           )

           (?<COLUMN>
               <Column (?{delete @s{map{'Column.' . $_}qw/Name AutoIncrement Required PrimaryKey Type Size Default/}})
                   ( \s+ (?&COLUMN_ATTR))+ (?:/>|>\s*</Column>)
           )

           (?<COLUMN_ADD>
               <ColumnAdd (?{delete @s{map{'Column.' . $_}qw/Name AutoIncrement Required PrimaryKey Type Size Default/}})
                   ( \s+ (?&COLUMN_ATTR))+ (?:/>|>\s*</ColumnAdd>)
           )

           (?<COLUMN_ATTR>
               (?:Name=".*?"(?{++$s{'Column.Name'}; $check->('Column.Name',1,1)})) |
               (?:AutoIncrement="(?:true|false)"(?{++$s{'Column.AutoIncrement'}; $check->('Column.AutoIncrement',1)})) |
               (?:Required="(?:true|false)"(?{++$s{'Column.Required'}; $check->('Column.Required',1)})) |
               (?:PrimaryKey="(?:true|false)"(?{++$s{'Column.PrimaryKey'}; $check->('Column.PrimaryKey',1)})) |
               (?:Type=".*?"(?{++$s{'Column.Type'}; $check->('Column.Type',1)})) |
               (?:Size="\d+"(?{++$s{'Column.Size'}; $check->('Column.Size',1)})) |
               (?:Default=".*?"(?{++$s{'Column.Default'}; $check->('Column.Default',1)}))
           )

           (?<COLUMN_CHANGE>
               <ColumnChange (?{delete @s{map{'Column.' . $_}qw/NameOld NameNew AutoIncrement Required PrimaryKey Type Size Default/}})
                   ( \s+ (?&COLUMN_CHANGE_ATTR))+ (?:/>|>\s*</ColumnChange>)
           )

           (?<COLUMN_CHANGE_ATTR>
               (?:NameOld=".*?"(?{++$s{'Column.NameOld'}; $check->('Column.NameOld',1)})) |
               (?:NameNew=".*?"(?{++$s{'Column.NameNew'}; $check->('Column.NameNew',1)})) |
               (?:AutoIncrement="(?:true|false)"(?{++$s{'Column.AutoIncrement'}; $check->('Column.AutoIncrement',1)})) |
               (?:Required="(?:true|false)"(?{++$s{'Column.Required'}; $check->('Column.Required',1)})) |
               (?:PrimaryKey="(?:true|false)"(?{++$s{'Column.PrimaryKey'}; $check->('Column.PrimaryKey',1)})) |
               (?:Type=".*?"(?{++$s{'Column.Type'}; $check->('Column.Type',1)})) |
               (?:Size="\d+"(?{++$s{'Column.Size'}; $check->('Column.Size',1)})) |
               (?:Default=".*?"(?{++$s{'Column.Default'}; $check->('Column.Default',1)}))
           )

           (?<COLUMN_DROP>
               <ColumnDrop (?{delete $s{'Column.Name'};})
                   ( \s+ (?&COLUMN_ATTR))+ (?:/>|>\s*</ColumnDrop>)
           )

           (?<COLUMN_ATTR>
               (?:Name=".*?"(?{++$s{'Column.Name'}; $check->('Column.Name',1,1)}))
           )

           (?<INSERT>
               <Insert (?{delete @s{map{'Insert.'. $_}qw/Table Type Version/};})
                   ( \s+ (?&INSERT_ATTR))+>
                   (\s+ (?&INSERT_DATA) )+ \s*
               </Insert>
           )

           (?<INSERT_ATTR>
               (?:Table=".*?"(?{++$s{'Insert.Table'}; $check->('Insert.Table',1,1)})) |
               (?:Type=".*?"(?{++$s{'Insert.Type'}; $check->('Insert.Type',1)})) |
               (?:Version=".*?"(?{++$s{'Insert.Version'}; $check->('Insert.Version',1)}))
           )

           (?<INSERT_DATA>
               <Data (?{delete @s{map{'Data.'. $_}qw/Key Type/};})
                   ( \s+ (?&INSERT_DATA_ATTR))+>
                   .*?
               </Data>
           )

           (?<INSERT_DATA_ATTR>
               (?:Key=".*?"(?{++$s{'Data.Key'}; $check->('Data.Key',1,1)})) |
               (?:Type=".*?"(?{++$s{'Data.Type'}; $check->('Data.Type',1)}))
           )

           (?<INDEX>
               <Index ( \s+ Name=".*?")?>
                   (\s+ (?&INDEX_COLUMN) )+ \s*
               </Index>
           )

           (?<INDEX_COLUMN>
               <IndexColumn (?{ delete $s{'Generic.Name'}; })
                   ( \s+ (?&NAME_ATTR))? (?:/>|>\s*</IndexColumn>)
           )

           (?<INDEX_CREATE>
               <IndexCreate (?{ delete $s{'Generic.Name'}; })
                   ( \s+ (?&NAME_ATTR))? (?:/>|>\s*</IndexCreate>)
           )

           (?<INDEX_DROP>
               <IndexDrop (?{ delete $s{'Generic.Name'}; })
                   ( \s+ (?&NAME_ATTR))? (?:/>|>\s*</IndexDrop>)
           )

           (?<UNIQUE>
               <Unique ( \s+ Name=".*?")?>
                   (\s+ (?&UNIQUE_COLUMN) )+ \s*
               </Unique>
           )

           (?<UNIQUE_COLUMN>
               <UniqueColumn (?{ delete $s{'Generic.Name'}; })
                   ( \s+ (?&NAME_ATTR))? (?:/>|>\s*</UniqueColumn>)
           )

           (?<UNIQUE_CREATE>
               <UniqueCreate (?{ delete $s{'Generic.Name'}; })
                   ( \s+ (?&NAME_ATTR))? (?:/>|>\s*</UniqueCreate>)
           )

           (?<UNIQUE_DROP>
               <UniqueDrop ( \s+ Name=".*?")? (?:/>|>\s*</UniqueDrop>)
           )

           (?<NAME_ATTR>
               (?:Name=".*?"(?{++$s{'Generic.Name'}; $check->('Generic.Name',1,1)}))
           )
     
           (?<FOREIGN_KEY>
               <ForeignKey (?{delete $s{'ForeignTable'};}) (?: \s+ (?&FOREIGN_TABLE) )+>
                   (\s+ (?&REFERENCE) )+ \s*
               </ForeignKey>
           )

           (?<FOREIGN_KEY_CREATE>
               <ForeignKeyCreate (?{ delete $s{'ForeignTable'}; })
                   ( \s+ (?&NAME_ATTR))? (?:/>|>\s*</ForeignKeyCreate>)
           )

           (?<FOREIGN_KEY_DROP>
               <ForeignKeyDrop ( \s+ Name=".*?")? (?:/>|>\s*</ForeignKeyDrop>)
           )

           (?<FOREIGN_TABLE>
               (?:ForeignTable=".*?"(?{++$s{'ForeignTable'}; $check->('ForeignTable',1,1)}))
           )

           (?<REFERENCE>
               <Reference (?{ delete @s{qw/Reference.Local Reference.Foreign/}; })
                   ( \s+ (?&REFERENCE_ATTR) )+ \s*
               (?:\s*/>|>\s*</Reference>)
           )

           (?<REFERENCE_ATTR>
               (?:Local=".*?"(?{++$s{'Reference.Local'}; $check->('Reference.Local',1,1)})) |
               (?:Foreign=".*?"(?{++$s{'Reference.Foreign'}; $check->('Reference.Foreign',1,1)}))
           )
       )
    }xms;

    return $check, $grammar;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Validate - Validate .opm files

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use v5.10;
    use OTRS::OPM::Validate;

    my $content = 'content of .opm file';
    my $success = eval {
        OTRS::OPM::Validate->validate( $content );
    };

    say "It's valid" if $success;

=head1 DESCRIPTION

I<.opm> files are used as addons for the ((OTRS)) Community Edition. They are
XML files with specific XML tags.

This module checks if all needed XML tags are there.

Currently the error messages might be misleading, this is something we are working on.

=head1 METHODS

=head2 validate

This checks the given string if it matches the needs. It C<die>s if an error occurs and returns C<1> otherwise.

    use v5.10;
    use OTRS::OPM::Validate;

    my $content = 'content of .opm file';
    my $success = eval {
        OTRS::OPM::Validate->validate( $content );
    };

    say "It's valid" if $success;

=head1 AUTHOR

Perl-Services.de <info@perl-services.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Perl-Services.de.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
