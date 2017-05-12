use strict;
use warnings;

package RT::Extension::Assets::Import::CSV;
use Text::CSV_XS;

our $VERSION = '2.2';

sub _column {
    ref($_[0]) ? (ref($_[0]) eq "CODE" ?
                      "code reference" :
                      "static value '${$_[0]}'")
        : "column $_[0]"
}

sub run {
    my $class = shift;
    my %args  = (
        CurrentUser => undef,
        File        => undef,
        Update      => undef,
        Insert      => undef,
        @_,
    );

    my $unique = RT->Config->Get('AssetsImportUniqueCF');
    my $unique_cf;
    if ($unique) {
        $unique_cf = RT::CustomField->new( $args{CurrentUser} );
        $unique_cf->LoadByCols(
            Name       => $unique,
            LookupType => RT::Asset->CustomFieldLookupType,
        );
        unless ($unique_cf->id) {
            RT->Logger->error( "Can't find custom field $unique for RT::Assets" );
            return (0, 0, 0);
        }
    }

    my $field2csv = RT->Config->Get('AssetsImportFieldMapping');
    my $csv2fields = {};
    push @{$csv2fields->{ $field2csv->{$_} }}, $_
        for grep { not ref $field2csv->{$_} } keys %{$field2csv};

    my %cfmap;
    for my $fieldname (keys %{ $field2csv }) {
        if ($fieldname =~ /^CF\.(.*)/) {
            my $cfname = $1;
            my $cf = RT::CustomField->new( $args{CurrentUser} );
            $cf->LoadByCols(
                Name       => $cfname,
                LookupType => RT::Asset->CustomFieldLookupType,
            );
            if ( $cf->id ) {
                $cfmap{$cfname} = $cf;
            } else {
                RT->Logger->warning(
                    "Missing custom field $cfname for "._column($field2csv->{$fieldname}).", skipping");
                delete $field2csv->{$fieldname};
            }
        } elsif ($fieldname =~ /^(id|Name|Status|Description|Catalog|Created|LastUpdated)$/) {
            # no-op, these are fine
        } elsif ( RT::Asset->HasRole($fieldname) ) {
            # no-op, roles are fine
        } else {
            RT->Logger->warning(
                "Unknown asset field $fieldname for "._column($field2csv->{$fieldname}).", skipping");
            delete $field2csv->{$fieldname};
        }
    }

    if (not $unique and not $field2csv->{"id"}) {
        RT->Logger->warning("No column set for 'id'; is AssetsImportUniqueCF intentionally unset?");
        return (0, 0, 0);
    }

    my @required_columns = ( $field2csv->{$unique ? "CF.$unique" : "id"} );

    my @items = $class->parse_csv( $args{File} );
    unless (@items) {
        RT->Logger->warning( "No items found in file $args{File}" );
        return (0, 0, 0);
    }

    RT->Logger->debug( "Found unused column '$_'" )
        for grep {not $csv2fields->{$_}} keys %{ $items[0] };
    RT->Logger->warning( "No column $_ found for @{$csv2fields->{$_}}" )
        for grep {not exists $items[0]->{$_} } keys %{ $csv2fields };

    RT->Logger->debug( 'Found ' . scalar(@items) . ' record(s)' );
    my ( $created, $updated, $skipped ) = (0) x 3;
    my $i = 1; # Because of header row
    my @later;
    for my $item (@items) {
        $i++;
        next unless grep {/\S/} values %{$item};

        my @missing = grep {not $item->{$_}} @required_columns;
        if (@missing) {
            if ($args{Insert}) {
                $item->{''} = $i;
                push @later, $item;
            } else {
                RT->Logger->warning(
                    "Missing value for required column@{[@missing > 1 ? 's':'']} @missing at row $i, skipping");
                $skipped++;
            }
            next;
        }

        my $assets = RT::Assets->new( $args{CurrentUser} );
        my $id_value = $class->get_value( $field2csv->{$unique ? "CF.$unique" : "id"}, $item );
        if ($unique) {
            $assets->LimitCustomField(
                CUSTOMFIELD => $unique_cf->id,
                VALUE       => $id_value,
            );
        } else {
            $assets->Limit( FIELD => "id", VALUE => $id_value );
        }

        if ( $assets->Count ) {
            if ( $assets->Count > 1 ) {
                RT->Logger->warning(
                    "Found multiple assets for @{[$unique||'id']} = $id_value"
                );
                $skipped++;
                next;
            }
            unless ( $args{Update} ) {
                RT->Logger->debug(
                    "Found existing asset at row $i but without 'Update' option, skipping."
                );
                $skipped++;
                next;
            }

            my $asset = $assets->First;
            my $changes;
            for my $field ( keys %$field2csv ) {
                my $value = $class->get_value( $field2csv->{$field}, $item );
                next unless defined $value and length $value;
                if ($field =~ /^CF\.(.*)/) {
                    my $cfname = $1;

                    if ($cfmap{$cfname}->Type eq "DateTime") {
                        my $args = { Content => $value };
                        $cfmap{$cfname}->_CanonicalizeValueDateTime( $args );
                        $value = $args->{Content};
                    } elsif ($cfmap{$cfname}->Type eq "Date") {
                        my $args = { Content => $value };
                        $cfmap{$cfname}->_CanonicalizeValueDate( $args );
                        $value = $args->{Content};
                    }

                    my @current = @{$asset->CustomFieldValues( $cfmap{$cfname}->id )->ItemsArrayRef};
                    next if grep {$_->Content and $_->Content eq $value} @current;

                    $changes++;
                    my ($ok, $msg) = $asset->AddCustomFieldValue(
                        Field => $cfmap{$cfname}->id,
                        Value => $value,
                    );
                    unless ($ok) {
                        RT->Logger->error("Failed to set CF $cfname to $value for row $i: $msg");
                    }
                } elsif ($asset->HasRole($field)) {
                    my $user = RT::User->new( $args{CurrentUser} );
                    $user->Load( $value );
                    $user = RT->Nobody unless $user->id;
                    next if $asset->RoleGroup($field)->HasMember( $user->PrincipalId );

                    $changes++;
                    my ($ok, $msg) = $asset->AddRoleMember( PrincipalId => $user->PrincipalId, Type => $field );
                    unless ($ok) {
                        RT->Logger->error("Failed to set $field to $value for row $i: $msg");
                    }
                } else {
                    if ($field eq "Catalog") {
                        my $catalog = RT::Catalog->new( $args{CurrentUser} );
                        $catalog->Load( $value );
                        $value = $catalog->id;
                    }

                    if ($asset->$field ne $value) {
                        $changes++;
                        my $method = "Set" . $field;
                        my ($ok, $msg) = $asset->$method( $value );
                        unless ($ok) {
                            RT->Logger->error("Failed to set $field to $value for row $i: $msg");
                        }
                    }
                }
            }
            if ($changes) {
                $updated++;
            } else {
                $skipped++;
            }
        } else {
            my $asset = RT::Asset->new( $args{CurrentUser} );
            my %args;

            for my $field (keys %$field2csv ) {
                my $value = $class->get_value($field2csv->{$field}, $item);
                next unless defined $value and length $value;
                if ($field =~ /^CF\.(.*)/) {
                    my $cfname = $1;
                    $args{"CustomField-".$cfmap{$cfname}->id} = $value;
                } else {
                    $args{$field} = $value;
                }
            }

            my ($ok, $msg, $err) = $asset->Create( %args );
            if ($ok) {
                $created++;
            } elsif ($err and @{$err}) {
                RT->Logger->warning(join("\n", "Warnings during create for row $i: ", @{$err}) );
            } else {
                RT->Logger->error("Failed to create asset for row $i: $msg");
            }
        }
    }

    unless ($unique) {
        # Update Asset sequence; mysql and SQLite do this implicitly
        my $dbtype = RT->Config->Get('DatabaseType');
        my $dbh = RT->DatabaseHandle->dbh;
        if ( $dbtype eq "Pg" ) {
            $dbh->do("SELECT setval('assets_id_seq', (SELECT MAX(id) FROM Assets))");
        } elsif ( $dbtype eq "Oracle" ) {
            my ($max) = $dbh->selectrow_array("SELECT MAX(id) FROM Assets");
            my ($cur) = $dbh->selectrow_array("SELECT Assets_seq.nextval FROM dual");
            if ($max > $cur) {
                $dbh->do("ALTER SEQUENCE Assets_seq INCREMENT BY ". ($max - $cur));
                # The next command _must_ be a select, and not a ->do,
                # or Oracle doesn't actually fetch from the sequence.
                $dbh->selectrow_array("SELECT Assets_seq.nextval FROM dual");
                $dbh->do("ALTER SEQUENCE Assets_seq INCREMENT BY 1");
            }
        }
    }

    for my $item (@later) {
        my $row = delete $item->{''};
        my $asset = RT::Asset->new( $args{CurrentUser} );
        my %args;

        for my $field (keys %$field2csv ) {
            my $value = $class->get_value($field2csv->{$field}, $item);
            next unless defined $value and length $value;
            if ($field =~ /^CF\.(.*)/) {
                my $cfname = $1;
                $args{"CustomField-".$cfmap{$cfname}->id} = $value;
            } else {
                $args{$field} = $value;
            }
        }

        my ($ok, $msg, $err) = $asset->Create( %args );
        if ($ok) {
            $created++;
        } elsif ($err and @{$err}) {
            RT->Logger->warning(join("\n", "Warnings during create for row $row: ", @{$err}) );
        } else {
            RT->Logger->error("Failed to create asset for row $row: $msg");
        }
    }

    return ( $created, $updated, $skipped );
}

sub get_value {
    my $class = shift;
    my ($from, $data) = @_;
    if (not ref $from) {
        return $data->{$from};
    } elsif (ref($from) eq "CODE") {
        return $from->($data);
    } else {
        return $$from;
    }
}

sub parse_csv {
    my $class = shift;
    my $file  = shift;

    my @rows;
    my $csv = Text::CSV_XS->new( { binary => 1 } );

    open my $fh, '<', $file or die "failed to read $file: $!";
    my $header = $csv->getline($fh);

    my @items;
    while ( my $row = $csv->getline($fh) ) {
        my $item;
        for ( my $i = 0 ; $i < @$header ; $i++ ) {
            if ( $header->[$i] ) {
                $item->{ $header->[$i] } = $row->[$i];
            }
        }

        push @items, $item;
    }

    $csv->eof or $csv->error_diag();
    close $fh;
    return @items;
}

=head1 NAME

RT-Extension-Assets-Import-CSV - RT Assets Import from CSV

=head1 PREREQUISITES

This version of RT::Extension::Assets::Import::CSV requires RT 4.4, as that
version of RT has Assets built in.

If you're running RT 4.2 with the Assets extension, you should seek an older
version of this extension; specifically, version 1.4.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::Assets::Import::CSV');

See L</CONFIGURATION>, below, for the remainder of the required
configuration.

=item Restart your webserver

=item Run C<bin/rt-assets-import-csv>

See C<bin/rt-assets-import-csv --help> for more information.

=back

=head1 CONFIGURATION

The following configuration would be used to import a three-column CSV
of assets, where the column titled C<serviceTag> is unique:

    Set( $AssetsImportUniqueCF, 'Service Tag' );
    Set( %AssetsImportFieldMapping,
        'Name'           => 'description',
        'CF.Service Tag' => 'serviceTag',
        'CF.Location'    => 'building',
        'CF.Serial #'    => 'serialNo',
    );

=head2 Constant values

If you want to set an RT column or custom field to a static value for
all imported assets, precede the "CSV field name" (right hand side of
the mapping) with a slash, like so:

    Set( $AssetsImportUniqueCF, 'Service Tag' );
    Set( %AssetsImportFieldMapping,
        'Name'           => 'description',
        'Catalog'        => \'Hardware',
        'CF.Service Tag' => 'serviceTag',
        'CF.Location'    => 'building',
        'CF.Serial #'    => 'serialNo',
    );

Every imported asset will now be added to the Hardware catalog in RT.
This feature is particularly useful for setting the asset catalog, but
may also be useful when importing assets from CSV sources you don't
control (and don't want to modify each time).

=head2 Computed values

You may also compute values during import, by passing a subroutine
reference as the value in the C<%AssetsImportFieldMapping>.  This
subroutine will be called with a hash reference of the parsed CSV row.

    Set( $AssetsImportUniqueCF, 'Service Tag' );
    Set( %AssetsImportFieldMapping,
        'Name'           => 'description',
        'CF.Service Tag' => 'serviceTag',
        'CF.Location'    => 'building',
        'CF.Weight'      => sub { $_[0]->{"Weight (kg)"} || "(unknown)" },
    );

Using computed columns may cause false-positive "unused column"
warnings; these can be ignored.

=head2 Numeric identifiers

If you are already using a numeric identifier to uniquely track your
assets, and wish RT to take over handling of that identifier, you can
choose to leave C<$AssetsImportUniqueCF> unset, and assign to C<id> in
the C<%AssetsImportFieldMapping>:

    Set( %AssetsImportFieldMapping,
        'id'             => 'serviceTag',
        'Name'           => 'description',
        'CF.Service Tag' => 'serviceTag',
        'CF.Serial #'    => 'serialNo',
    );

This requires that, after the import, RT becomes the generator of all
asset ids.  Otherwise, asset id conflicts may occur.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-Assets-Import-CSV@rt.cpan.org|mailto:bug-RT-Extension-Assets-Import-CSV@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Assets-Import-CSV>.

=head1 COPYRIGHT

This extension is Copyright (C) 2014-2016 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
