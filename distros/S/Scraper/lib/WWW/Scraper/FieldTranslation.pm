use strict;
package WWW::Scraper::FieldTranslation;
use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);
use Tie::Persistent;
use Storable;

sub new {
    my ($self, $engineName, $rqstName, $fieldName, $newFieldName) = @_;
    $self = bless {}, $self;
    
    $self->{'_state'}   = 0;    # Current state of FieldTranslation object -
                                #  0 - no initialization done
                                #  1 - persistent hash is opened to read
                                #  2 - persistent hash is opened to read/write
    $self->{'_engineName'}  = $engineName;
    $self->{'_requestName'} = $rqstName;
    $self->{'_fieldName'}   = $fieldName;
    $self->{'_newFieldName'}= $newFieldName;

    $self->{'_translationSearchPath'} = \@INC;
    $self->{'_translationTie'} = undef;
    
    return $self;
}




### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Translate from the canonical Request->locations to the Engine's native option,
# using values from the persistent tied file "<engineName>.<requestType>.locations";
#
# The values in %LocationsTie might be an array of values, and of course
# the same value could be in multiple elements, so we gather all the
# translations up in a hash to insure each value appears just once in
# the result.
sub translate {
    my ($self, $scraper, $rqst, $val) = @_;
    my (%results, @postSelect);
    my ($rsltRtn, $postSelectRtn);

    my $LT = $self->_setupTranslation(1);

    my $aval = $val;
    $aval = [$val] unless 'ARRAY' eq ref $val;
    my ($va, $v);

    for ( @$aval ) {
        my $prepost = $$LT{$_};
        for ( keys %$prepost ) {
            $v = $$prepost{$_};
            # The 'pre' array of the Field Translation table.
            if ( m/^pre/ ) {
                %results = %$v;
                $rsltRtn = \%results;
            }
            # The 'post' array of the Field Translation table.
            elsif ( m/^post/ ) {
                push @postSelect, $v;
                $postSelectRtn = \@postSelect
            }
        }
    }
    
    $self->{'_postSelect'}{$_} = $postSelectRtn;
    return $rsltRtn;
}



sub postSelect {
    my ($self, $scraper, $rqst, $rslt) = @_;
    
    my $val;
    for ( keys %{$self->{'_postSelect'}} ) {
        my $pstSlct = ${$self->{'_postSelect'}}{$_};
        if ( $pstSlct ) {
            my $match = 0;
MATCH:      for my $chkIt ( @$pstSlct ) {
               for my $fldnam ( keys %$chkIt ) {
                    $val = $rslt->_elem($fldnam);
                    my $qrs = $$chkIt{$fldnam};
                    if ( ref($qrs) eq 'ARRAY' ) {
                        for ( @$qrs ) {
                            if ( $val =~ m/$_/ ) {
                                $match = 1;
                                last MATCH;
                            }
                        }
                    }
                    else {
                        if ( $val =~ m/$qrs/ ) {
                            $match = 1;
                            last MATCH;
                        }
                    }
                }
            }
            # If no match, then record the disqualifying field for posterity, and return 0.
            unless ( $match ) {
                $self->{'_unTranslationTie'}{$val} += 1;
                return 0;
            }
        }
    }
    return 1;
}




### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
sub setTranslation {
    my ($self, $key, $val) = @_;
    my $LT = $self->_setupTranslation(2);
    my $orgVal = $$LT{$key};
    $$LT{$key} = $val if defined $val;
    return $orgVal;
}
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# $typ == 0, readable; $typ == 1, read/writable.
sub _setupTranslation {
    my ($self, $typ) = @_;

    return $self->{'_translationTie'} if ($typ == $self->{'_state'});
    
    my $TranslationsSearchPath = $self->{'_translationSearchPath'};
    my $prefix = ref $self;
    $prefix =~ s/FieldTranslation.*$//;
    $prefix =~ s-::-/-g;
    my $engineName = $prefix.$self->{'_engineName'};
    $engineName .= '.' if $engineName;
    my $rqstName   = $self->{'_requestName'};
    $rqstName .= '.' if $rqstName;
    my $fieldName   = $self->{'_fieldName'};
    
    my $tieFile;
    for ( @$TranslationsSearchPath ) {
        $tieFile = "$_/$engineName$rqstName$fieldName";
        last if -f $tieFile;
    };
    # If couldn't find the transformations definition file, then
    # create one in the same folder that <ScraperModule>.pm is in.
    unless ( -f $tieFile ) {
        for ( @$TranslationsSearchPath ) {
            if ( -f "$_/$engineName"."pm" ) {
                $tieFile = "$_/$engineName$rqstName$fieldName";
                last;
            }
        }
    }
    my %TranslationTie;
    tie (%TranslationTie, 'Tie::Persistent', $tieFile, ($typ == 2) ? 'rw' : 'r') or 
        die "Can't tie $engineName$rqstName$fieldName: $!";
    my %UnTranslationTie;
    tie (%UnTranslationTie, 'Tie::Persistent', $tieFile.'.mismatch', 'rw') or 
        die "Can't tie $engineName$rqstName$fieldName.mismatch: $!";

    $self->{'_state'} = $typ;
    $self->{'_translationTie'} = \%TranslationTie;
    $self->{'_unTranslationTie'} = \%UnTranslationTie;
    return ($self->{'_translationTie'}, $self->{'_unTranslationTie'}) if wantarray;
    return $self->{'_translationTie'};
}



# A generalize get/set method for object attributes.
sub _attr {
    my ($self, $attr, $value) = @_;
    my $rtn = $self->{$attr};
    $self->{$attr} = $value if defined $value;
    if ( wantarray ) {
        return $rtn if 'ARRAY' eq ref $rtn;
        return [$rtn];
    }
    return $rtn;
}
sub debug          { $_[0]->_attr('_debug', $_[1]) }

1;

__END__

=head1 NAME

WWW::Scraper::FieldTranslation - Canonical form for Scraper FieldTranslations

=head1 SYNOPSIS

    use WWW::Scraper::FieldTranslation;

    $FieldTranslation = new WWW::Scraper::FieldTranslation( $requestType, $engineType );

=head1 DESCRIPTION

=head1 METHODS

=head2 debug

The C<debug> method sets the debug tracing level to the value of its first parameter.

=head1 TRANSLATIONS

 PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER
 PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER
 PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER
 PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER PLACEHOLDER
The Scraper modules that do table driven field translations (from canonical FieldTranslations to native FieldTranslations) will have
files included in their package representing the translation table in Storable format. The names of these files are
<ScraperModuleName>.<FieldTranslationType>.<canonicalFieldName>. E.G., Brainpower.pm owns a translation table for the 'locations'
field of the canonical FieldTranslation::Job module; it is named C<Brainpower.Job.locations> . 

The Scraper module will locate the translation file, when required, by searching the @INC path-search until it is found
(the same path-search Perl uses to locate Perl modules.)

=head2 set<fieldName>Translation()

The methods set<fieldName>Translations() can be used to help maintain these translation files. 
For instance, setLocationsTranslation('canonical', 'native') will establish a translation from 'canonical' to 'native'
for the 'locations' FieldTranslation field.

    setLocationsTranslation('CA-San Jose', 5);       # CA-San Jose => '5'
    setLocationsTranslation('CA-San Jose', [5,6]);   # CA-San Jose => '5' + '6'
    
If you have used this method to upgrade your translations, 
then a new upgrade of F<WWW::Scraper> will probably over-write your tranlation file(s),
so watch out for that! Back up your translation files before upgrading F<WWW::Scraper>!

=head1 AUTHOR

C<WWW::Scraper::FieldTranslation> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



# Contract Type (from Dice)
# No Restrictions
# Contract - W2
# Contract - Independent
# Contract - Corp-to-Corp
# Contract to Hire - W2
# Contract to Hire - Independent
# Contract to Hire - Corp-to-Corp
# Full - time

