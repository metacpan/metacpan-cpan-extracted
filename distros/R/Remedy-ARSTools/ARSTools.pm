###################################################
## ARSTools.pm
## Andrew N. Hicox	<andrew@hicox.com>
##
## A perl wrapper class for ARSPerl
## a nice interface for remedy functions.
###################################################


## global stuff ###################################
package Remedy::ARSTools;
use 5.6.0;
use strict;
require Exporter;

use AutoLoader qw(AUTOLOAD);
use ARS;
use Date::Parse;
use Time::Interval;

#class global vars
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $errstr %currency_codes);
@ISA 		= qw(Exporter);
@EXPORT		= qw(&ParseDBDiary &EncodeDBDiary);
@EXPORT_OK	= qw($VERSION $errstr);
$VERSION	= 1.25;

## this is a global lookup table for currencies
our %currency_codes = (
	'ARS' => { 'name' => "Argentina Peso", 'ascii_prefix_sequence' => ['36'] },
	'AUD' => { 'name' => "Australia Dollar", 'ascii_prefix_sequence' => ['36'] },
	'BSD' => { 'name' => "Bahamas Dollar", 'ascii_prefix_sequence' => ['36'] },
	'BBD' => { 'name' => "Barbados Dollar", 'ascii_prefix_sequence' => ['36'] },
	'BMD' => { 'name' => "Bermuda Dollar", 'ascii_prefix_sequence' => ['36'] },
	'BND' => { 'name' => "Brunei Darussalam Dollar", 'ascii_prefix_sequence' => ['36'] },
	'CAD' => { 'name' => "Canada Dollar", 'ascii_prefix_sequence' => ['36'] },
	'KYD' => { 'name' => "Cayman Islands Dollar", 'ascii_prefix_sequence' => ['36'] },
	'CLP' => { 'name' => "Chile Peso", 'ascii_prefix_sequence' => ['36'] },
	'COP' => { 'name' => "Colombia Peso", 'ascii_prefix_sequence' => ['36'] },
	'XCD' => { 'name' => "East Caribbean Dollar", 'ascii_prefix_sequence' => ['36'] },
	'SVC' => { 'name' => "El Salvador Colon", 'ascii_prefix_sequence' => ['36'] },
	'FJD' => { 'name' => "Fiji Dollar", 'ascii_prefix_sequence' => ['36'] },
	'GYD' => { 'name' => "Guyana Dollar", 'ascii_prefix_sequence' => ['36'] },
	'HKD' => { 'name' => "Hong Kong Dollar", 'ascii_prefix_sequence' => ['36'] },
	'LRD' => { 'name' => "Liberia Dollar", 'ascii_prefix_sequence' => ['36'] },
	'MXN' => { 'name' => "Mexico Peso", 'ascii_prefix_sequence' => ['36'] },
	'NAD' => { 'name' => "Namibia Dollar", 'ascii_prefix_sequence' => ['36'] },
	'NZD' => { 'name' => "New Zealand Dollar", 'ascii_prefix_sequence' => ['36'] },
	'SGD' => { 'name' => "Singapore Dollar", 'ascii_prefix_sequence' => ['36'] },
	'SBD' => { 'name' => "Solomon Islands Dollar", 'ascii_prefix_sequence' => ['36'] },
	'SRD' => { 'name' => "Suriname Dollar", 'ascii_prefix_sequence' => ['36'] },
	'TVD' => { 'name' => "Tuvalu Dollar", 'ascii_prefix_sequence' => ['36'] },
	'USD' => { 'name' => "United States Dollar", 'ascii_prefix_sequence' => ['36'], 'match_preference' => 1 },
	'HNL' => { 'name' => "Honduras Lempira", 'ascii_prefix_sequence' => ['76'] },
	'BWP' => { 'name' => "Botswana Pula", 'ascii_prefix_sequence' => ['80'] },
	'GTQ' => { 'name' => "Guatemala Quetzal", 'ascii_prefix_sequence' => ['81'] },
	'ZAR' => { 'name' => "South Africa Rand", 'ascii_prefix_sequence' => ['82'] },
	'SOS' => { 'name' => "Somalia Shilling", 'ascii_prefix_sequence' => ['83'] },
	'GHC' => { 'name' => "Ghana Cedis", 'ascii_prefix_sequence' => ['162'] },
	'EGP' => { 'name' => "Egypt Pound", 'ascii_prefix_sequence' => ['163'] },
	'FKP' => { 'name' => "Falkland Islands (Malvinas) Pound", 'ascii_prefix_sequence' => ['163'] },
	'GIP' => { 'name' => "Gibraltar Pound", 'ascii_prefix_sequence' => ['163']},
	'GGP' => { 'name' => "Guernsey Pound", 'ascii_prefix_sequence' => ['163'] },
	'IMP' => { 'name' => "Isle of Man Pound", 'ascii_prefix_sequence' => ['163'] },
	'JEP' => { 'name' => "Jersey Pound", 'ascii_prefix_sequence' => ['163'] },
	'LBP' => { 'name' => "Lebanon Pound", 'ascii_prefix_sequence' => ['163'] },
	'SHP' => { 'name' => "Saint Helena Pound", 'ascii_prefix_sequence' => ['163'] },
	'SYP' => { 'name' => "Syria Pound", 'ascii_prefix_sequence' => ['163'] },
	'GBP' => { 'name' => "United Kingdom Pound", 'ascii_prefix_sequence' => ['163'], 'match_preference' => 1 },
	'CNY' => { 'name' => "China Yuan Renminbi", 'ascii_prefix_sequence' => ['165'] },
	'JPY' => { 'name' => "Japan Yen", 'ascii_prefix_sequence' => ['165'], 'match_preference' => 1 },
	'AWG' => { 'name' => "Aruba Guilder", 'ascii_prefix_sequence' => ['402'] },
	'ANG' => { 'name' => "Netherlands Antilles Guilder", 'ascii_prefix_sequence' => ['402'], 'match_preference' => 1 },
	'AFN' => { 'name' => "Afghanistan Afghani", 'ascii_prefix_sequence' => ['1547'] },
	'THB' => { 'name' => "Thailand Baht", 'ascii_prefix_sequence' => ['3647'] },
	'KHR' => { 'name' => "Cambodia Riel", 'ascii_prefix_sequence' => ['6107'] },
	'CRC' => { 'name' => "Costa Rica Colon", 'ascii_prefix_sequence' => ['8353'] },
	'TRL' => { 'name' => "Turkey Lira", 'ascii_prefix_sequence' => ['8356'] },
	'NGN' => { 'name' => "Nigeria Naira", 'ascii_prefix_sequence' => ['8358'] },
	'MUR' => { 'name' => "Mauritius Rupee", 'ascii_prefix_sequence' => ['8360'] },
	'NPR' => { 'name' => "Nepal Rupee", 'ascii_prefix_sequence' => ['8360'], 'match_preference' => 1 },
	'PKR' => { 'name' => "Pakistan Rupee", 'ascii_prefix_sequence' => ['8360'] },
	'SCR' => { 'name' => "Seychelles Rupee", 'ascii_prefix_sequence' => ['8360'] },
	'LKR' => { 'name' => "Sri Lanka Rupee", 'ascii_prefix_sequence' => ['8360'] },
	'KPW' => { 'name' => "Korea (North) Won", 'ascii_prefix_sequence' => ['8361'] },
	'KRW' => { 'name' => "Korea (South) Won", 'ascii_prefix_sequence' => ['8361'] , 'match_preference' => 1 },
	'ILS' => { 'name' => "Israel Shekel", 'ascii_prefix_sequence' => ['8362'] },
	'VND' => { 'name' => "Viet Nam Dong", 'ascii_prefix_sequence' => ['8363'] },
	'EUR' => { 'name' => "Euro Member Countries", 'ascii_prefix_sequence' => ['8364'] },
	'LAK' => { 'name' => "Laos Kip", 'ascii_prefix_sequence' => ['8365'] },
	'MNT' => { 'name' => "Mongolia Tughrik", 'ascii_prefix_sequence' => ['8366'] },
	'CUP' => { 'name' => "Cuba Peso", 'ascii_prefix_sequence' => ['8369'] },
	'PHP' => { 'name' => "Philippines Peso", 'ascii_prefix_sequence' => ['8369'], 'match_preference' => 1 },
	'UAH' => { 'name' => "Ukraine Hryvna", 'ascii_prefix_sequence' => ['8372'] },
	'IRR' => { 'name' => "Iran Rial", 'ascii_prefix_sequence' => ['65020'] },
	'OMR' => { 'name' => "Oman Rial", 'ascii_prefix_sequence' => ['65020'] },
	'QAR' => { 'name' => "Qatar Riyal", 'ascii_prefix_sequence' => ['65020'] },
	'SAR' => { 'name' => "Saudi Arabia Riyal", 'ascii_prefix_sequence' => ['65020'], 'match_preference' => 1 },
	'YER' => { 'name' => "Yemen Rial", 'ascii_prefix_sequence' => ['65020'] },
	'RSD' => { 'name' => "Serbia Dinar", 'ascii_prefix_sequence' => ['1044', '1080', '1085', '46'] },
	'HRK' => { 'name' => "Croatia Kuna", 'ascii_prefix_sequence' => ['107', '110'] },
	'DKK' => { 'name' => "Denmark Krone", 'ascii_prefix_sequence' => ['107', '114'], 'match_preference' => 1 },
	'EEK' => { 'name' => "Estonia Kroon", 'ascii_prefix_sequence' => ['107', '114'] },
	'ISK' => { 'name' => "Iceland Krona", 'ascii_prefix_sequence' => ['107', '114'] },
	'NOK' => { 'name' => "Norway Krone", 'ascii_prefix_sequence' => ['107', '114'] },
	'SEK' => { 'name' => "Sweden Krona", 'ascii_prefix_sequence' => ['107', '114'] },
	'MKD' => { 'name' => "Macedonia Denar", 'ascii_prefix_sequence' => ['1076', '1077', '1085'] },
	'RON' => { 'name' => "Romania New Leu", 'ascii_prefix_sequence' => ['108', '101', '105'] },
	'BGN' => { 'name' => "Bulgaria Lev", 'ascii_prefix_sequence' => ['1083', '1074'] },
	'KZT' => { 'name' => "Kazakhstan Tenge", 'ascii_prefix_sequence' => ['1083', '1074'], 'match_preference' => 1 },
	'KGS' => { 'name' => "Kyrgyzstan Som", 'ascii_prefix_sequence' => ['1083', '1074'] },
	'UZS' => { 'name' => "Uzbekistan Som", 'ascii_prefix_sequence' => ['1083', '1074'] },
	'AZN' => { 'name' => "Azerbaijan New Manat", 'ascii_prefix_sequence' => ['1084', '1072', '1085'] },
	'RUB' => { 'name' => "Russia Ruble", 'ascii_prefix_sequence' => ['1088', '1091', '1073'] },
	'BYR' => { 'name' => "Belarus Ruble", 'ascii_prefix_sequence' => ['112', '46'] },
	'PLN' => { 'name' => "Poland Zloty", 'ascii_prefix_sequence' => ['122', '322'] },
	'UYU' => { 'name' => "Uruguay Peso", 'ascii_prefix_sequence' => ['36', '85'] },
	'BOB' => { 'name' => "Bolivia Boliviano", 'ascii_prefix_sequence' => ['36', '98'] },
	'VEF' => { 'name' => "Venezuela Bolivar", 'ascii_prefix_sequence' => ['66', '115'] },
	'PAB' => { 'name' => "Panama Balboa", 'ascii_prefix_sequence' => ['66', '47', '46'] },
	'BZD' => { 'name' => "Belize Dollar", 'ascii_prefix_sequence' => ['66', '90', '36'] },
	'NIO' => { 'name' => "Nicaragua Cordoba", 'ascii_prefix_sequence' => ['67', '36'] },
	'CHF' => { 'name' => "Switzerland Franc", 'ascii_prefix_sequence' => ['67', '72', '70'] },
	'HUF' => { 'name' => "Hungary Forint", 'ascii_prefix_sequence' => ['70', '116'] },
	'PYG' => { 'name' => "Paraguay Guarani", 'ascii_prefix_sequence' => ['71', '115'] },
	'JMD' => { 'name' => "Jamaica Dollar", 'ascii_prefix_sequence' => ['74', '36'] },
	'CZK' => { 'name' => "Czech Republic Koruna", 'ascii_prefix_sequence' => ['75', '269'] },
	'BAM' => { 'name' => "Bosnia and Herzegovina Convertible Marka", 'ascii_prefix_sequence' => ['75', '77'] },
	'ALL' => { 'name' => "Albania Lek", 'ascii_prefix_sequence' => ['76', '101', '107'] },
	'LVL' => { 'name' => "Latvia Lat", 'ascii_prefix_sequence' => ['76', '115'] },
	'LTL' => { 'name' => "Lithuania Litas", 'ascii_prefix_sequence' => ['76', '116'] },
	'MZN' => { 'name' => "Mozambique Metical", 'ascii_prefix_sequence' => ['77', '84'] },
	'TWD' => { 'name' => "Taiwan New Dollar", 'ascii_prefix_sequence' => ['78', '84', '36'] },
	'IDR' => { 'name' => "Indonesia Rupiah", 'ascii_prefix_sequence' => ['82', '112'] },
	'BRL' => { 'name' => "Brazil Real", 'ascii_prefix_sequence' => ['82', '36'] },
	'DOP' => { 'name' => "Dominican Republic Peso", 'ascii_prefix_sequence' => ['82', '68', '36'] },
	'MYR' => { 'name' => "Malaysia Ringgit", 'ascii_prefix_sequence' => ['82', '77'] },
	'PEN' => { 'name' => "Peru Nuevo Sol", 'ascii_prefix_sequence' => ['83', '47', '46'] },
	'TTD' => { 'name' => "Trinidad and Tobago Dollar", 'ascii_prefix_sequence' => ['84', '84', '36'] },
	'ZWD' => { 'name' => "Zimbabwe Dollar", 'ascii_prefix_sequence' => ['90', '36'] }
);


## new ############################################
sub new {

	#take the class name off the arg list, if it's called that way
	shift() if ($_[0] =~/^Remedy/);

	#bless yourself, baby!
	my $self = bless({@_});

	#the following options are required
	foreach ('Server', 'User', 'Pass'){
		exists($self->{$_}) || do {
			$errstr = $_ . " is a required option for creating an object";
			warn($errstr) if $self->{'Debug'};
			return (undef);
		};
	}

	#default options
	$self->{'ReloadConfigOK'} = 1 if ($self->{'ReloadConfigOK'} =~/^\s*$/);
	$self->{'GenerateConfig'} = 1 if ($self->{'GenerateConfig'} =~/^\s*$/);
	$self->{'TruncateOK'}     = 1 if ($self->{'TruncateOK'} =~/^\s*$/);
	$self->{'Port'} = undef if ($self->{'Port'} !~/^\d+/);
	$self->{'DateTranslate'}  = 1 if ($self->{'DateTranslate'} =~/^\s*$/);
	$self->{'TwentyFourHourTimeOfDay'} = 0  if ($self->{'TwentyFourHourTimeOfDay'} =~/^\s*$/);
	$self->{'OverrideJoinSubmitQuery'} = 0 if ($self->{'OverrideJoinSubmitQuery'} =~/^\s*$/);
	#default options apply only to ARS >= 1.8001
	$self->{'Language'} = undef if ($self->{'Language'} =~/^\s*$/);
	$self->{'AuthString'} = undef if ($self->{'AuthString'} =~/^\s*$/);
	$self->{'RPCNumber'} = undef if ($self->{'RPCNumber'} =~/^\s*$/);


	#load config file
	$self->LoadARSConfig() || do {
	        $errstr = $self->{'errstr'};
	        warn ($errstr) if $self->{'Debug'};
	        return (undef);
	};

	#get a control token (unless 'LoginOverride' is set)
	unless ($self->{'LoginOverride'}){
		$self->ARSLogin() || do {
			$errstr = $self->{'errstr'};
			warn ($errstr) if $self->{'Debug'};
			return (undef)
		};
	}

	#bye, now!
	return($self);

}




## LoadARSConfig ##################################
## load the config file with field definitions
sub LoadARSConfig {

	my ($self, %p) = @_;

	#if the file dosen't exist (or is marked stale), load data from Remedy instead
	if ( (! -e $self->{'ConfigFile'}) || ($self->{'staleConfig'} > 0) ) {

		#blow away object's current config (if we have one)
		$self->{'__oldARSConfig'} = $self->{'ARSConfig'};
		$self->{'ARSConfig'} = ();

		#get a control structure if we don't have one
		$self->ARSLogin();

		#if no 'Schemas' defined on object, pull data for all
		if (! $self->{'Schemas'}){
			warn ("getting schema list from server") if $self->{'Debug'};
			@{$self->{'Schemas'}} = ARS::ars_GetListSchema($self->{'ctrl'}) || do {
				$self->{'errstr'} = "LoadARSConfig: can't retrieve schema list (all): " . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}

		#get field data for each schema
		foreach (@{$self->{'Schemas'}}){

			## NEW HOTNESS (1.11) -- we have to capture metadata about the form, like primarily ... is it a join form?
			warn ("getting schema metadata for " . $_) if $self->{'Debug'};
			my $md_tmp = ARS::ars_GetSchema($self->{'ctrl'}, $_) || do {
				$self->{'errstr'} = "LoadARSConfig: can't retrieve schema meta-data for: " . $_ . ": " . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return(undef);
			};
			if ((ref($md_tmp) eq "HASH") && (exists($md_tmp->{'schema'}))){
				$self->{'ARSConfig'}->{$_}->{'_schema_info'} = $md_tmp->{'schema'};
			}else{
				warn("cannot get schema info from this version of the API. CreateTicket will not work against join forms") if ($self->{'Debug'});
			}

			## OLD but not busted
			warn ("getting field list for " . $_) if $self->{'Debug'};

			#get field list ...
			(my %fields = ARS::ars_GetFieldTable($self->{'ctrl'}, $_)) || do {
				$self->{'errstr'} = "LoadARSConfig: can't retrieve table data for " . $_ . ": " . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};


			#get meta-data for each field
			foreach my $field (keys %fields){

				#set field id
				$self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'id'} = $fields{$field};

				#get meta-data
				(my $tmp = ARS::ars_GetField(
					$self->{'ctrl'},	#control token
					$_,			#schema name
					$fields{$field}		#field id
				)) || do {
					$self->{'errstr'} = "LoadARSConfig: can't get field meta-data for " . $_ . " / " . $field .
					          ": " . $ARS::ars_errstr;
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};

				## 1.15 - stash the field's "option" (i.e. "entry_mode": required, optional or display-only)
				if (defined($tmp->{'option'})){
					if ($tmp->{'option'} == 1){
						$self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'entry_mode'} = "required";
					}elsif ($tmp->{'option'} == 2){
						$self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'entry_mode'} = "optional";
					}elsif ($tmp->{'option'} == 4){
						$self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'entry_mode'} = "display-only";
					}else{
						warn ("LoadARSConfig: encountered unknown 'option' value (" . $tmp->{'option'} . ") on Schema: " . $_ . " / field: " . $field) if ($self->{'Debug'});
						$self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'entry_mode'} = $tmp->{'option'};
					}
				}

				## NEW HOTNESS (1.02)
				## depending on the C-api version that ARSperl was compiled against, the data we're looking
				## for may be in one of two locations. We'll check both, and take the one that has data
				if ( defined($tmp->{'dataType'}) ){

					## some 1.06 hotness ... stash the field dataType too
					$self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'dataType'} = $tmp->{'dataType'};

				        if ($tmp->{'dataType'} eq "enum"){
				                #handle enums
				                $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'enum'} = 1;
				                if (ref($tmp->{'limit'}) eq "ARRAY"){
				                        #found it in the old place
				                        $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'vals'} = $tmp->{'limit'};
                                                }elsif ( defined($tmp->{'limit'}) && defined($tmp->{'limit'}->{'enumLimits'}) && ( ref($tmp->{'limit'}->{'enumLimits'}->{'regularList'}) eq "ARRAY")){
                                                        #found it in the new place
                                                        $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'vals'} = $tmp->{'limit'}->{'enumLimits'}->{'regularList'};

                                                ## EVEN NEWER HOTNESS (1.04)
                                                ## handle enums with custom value lists
                                                }elsif ( defined($tmp->{'limit'}) && defined($tmp->{'limit'}->{'enumLimits'}) && ( ref($tmp->{'limit'}->{'enumLimits'}->{'customList'}) eq "ARRAY")){


                                                        ## NEW HOTNESS -- we'll just use a hash
                                                        ## 'ARSConfig'->{schema}->{fields}->{field}->{'enum'} = 1 (regular enum)
                                                        ## 'ARSConfig'->{schema}->{fields}->{field}->{'enum'} = 2 (custom enum -- use the hash)
                                                        ## the hash will be where the 'vals' array used to be. The string will be the key. The enum will be the value
                                                        $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'enum'} = 2;
                                                        foreach my $blah (@{$tmp->{'limit'}->{'enumLimits'}->{'customList'}}){
                                                                $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'vals'}->{$blah->{'itemName'}} = $blah->{'itemNumber'};
                                                        }
                                                }else {
                                                        #didn't find it at all
                                                        $self->{'errstr'} = "LoadARSConfig: I can't find the enum list for this field! " . $field . "(" . $fields{$field} . ")";
                                                        warn($self->{'errstr'}) if $self->{'Debug'};
                                                        return (undef);
                                                }
				        }else{
				                #handle everything else (we rolls like that, yo)
				                if ( defined($tmp->{'maxLength'}) && ($tmp->{'maxLength'} =~/^\d+$/)){
				                        #found it in the old place
				                        $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'length'} = $tmp->{'maxLength'};
                                                }elsif (defined($tmp->{'limit'}) && defined($tmp->{'limit'}->{'maxLength'}) && ($tmp->{'limit'}->{'maxLength'} =~/^\d+$/)) {
                                                        #found it in the new place
                                                        $self->{'ARSConfig'}->{$_}->{'fields'}->{$field}->{'length'} = $tmp->{'limit'}->{'maxLength'};
                                                }
				        }
                                }else{
                                        $self->{'errstr'} = "LoadARSConfig: I can't find field limit data on this version of the API!";
                                        warn($self->{'errstr'}) if $self->{'Debug'};
                                        return (undef);
                                }
			}
		}

		## if we had staleConfig, merge anything from the old one that is MISSING from the new one
		## it is a cache after all :-)
		foreach my $_schema (keys (%{$self->{'ARSConfig'}})){

			#skip internal shiznit
			if ($_schema =~/^__/){ next; }

			#dooo ieeeeet!
			$self->{'ARSConfig'}->{$_schema} = $self->{'__oldARSConfig'}->{$_schema} if (! exists($self->{'ARSConfig'}->{$_schema}));

		}

		#unset staleConfig flag
		delete($self->{'__oldARSConfig'}) if (exists($self->{'__oldARSConfig'}));
		$self->{'staleConfig'} = 0;


		## new for 1.06, keep Remedy::ARSTools::VERSION in the config, so we can know later if we need to upgrade it
		$self->{'ARSConfig'}->{'__Remedy_ARSTools_Version'} = $Remedy::ARSTools::VERSION;

		#now that we have our data, write the file (if we have the flag)
		if ($self->{'GenerateConfig'} > 0){
			require Data::DumpXML;
			my $xml = Data::DumpXML::dump_xml($self->{'ARSConfig'});
			warn("LoadARSConfig: exported field data to XML") if $self->{'Debug'};
			open (CFG, ">" . $self->{'ConfigFile'}) || do {
				$self->{'errstr'} = "LoadARSConfig: can't open config file for writing: " . $!;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return(undef);
			};
			print CFG $xml, "\n";
			close(CFG);
			warn("LoadARSConfig: exported field data to config file: " . $self->{'ConfigFile'}) if $self->{'Debug'};

			#we're done here
			return (1);
		}

	#otherwise, load it from the file
	}else{

		#open config file
		open (CFG, $self->{'ConfigFile'}) || do {
			$self->{'errstr'} = "LoadARSConfig: can't open specified config file: "  . $!;
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};

		#parse it
		require Data::DumpXML::Parser;
		my $parser = Data::DumpXML::Parser->new();
		eval { $self->{ARSConfig} = $parser->parsestring(join("", <CFG>)); };
		if ($@){
			$self->{'errstr'} = "LoadARSConfig: can't parse config data from file: " . $@;
			warn($self->{'errstr'}) if $self->{'Debug'};
		}
		close (CFG);

		#actually just the first element will do ;-)
		$self->{'ARSConfig'} = $self->{'ARSConfig'}->[0];

		## new for 1.06 ... upgrade the config if it was created with an earlier version of Remedy::ARSTools
		if ($self->{'ARSConfig'}->{'__Remedy_ARSTools_Version'} < 1.15){
			warn("LoadARSConfig: re-generating config generated with earlier version of Remedy::ARSTools") if $self->{'Debug'};
			$self->{'staleConfig'} = 1;
			$self->LoadARSConfig();
		}
		warn("LoadARSConfig: loaded config from file") if $self->{'Debug'};

		## new for 1.15 - check the loaded config to make sure it has all of the 'Schemas', if not mark the config stale, and refresh it
		foreach my $schema (@{$self->{'Schemas'}}){
			exists($self->{'ARSConfig'}->{$schema}) || do {
				warn ("LoadARSConfig: loaded cache file missing schema: " . $schema) if ($self->{'Debug'});
				$self->{'staleConfig'} = 1;
			};
		}
		if ($self->{'staleConfig'} > 0){
			warn ("LoadARSConfig: refreshing cache from server ...");
			$self->LoadARSConfig();
		}

		return(1);
	}
}




## ARSLogin #######################################
## if not already logged in ... get ars token.
## this is a sneaky hack to get around perl compiler
## errors thrown on behalf of the function prototypes
## in ARSperl, which change based on the version
## installed.
sub ARSLogin {
	my $self = shift();

	#actually, just distribute the call based on the ARSperl version
	if ($ARS::VERSION < 1.8001){
		return ($self->ARSLoginOld(@_));
	}else{
		return ($self->ARSLoginNew(@_));
	}
}

## Query ###########################################
## return selected fields from records matching the
## given QBE string in the specified schema.
## this is also a sneaky hack to call the correct
## syntax for ars_GetListEntry based on the ARSperl
## version number
sub Query {
	my $self = shift();

	#actually, just distribute the call based on the ARSperl version
	if ($ARS::VERSION < 1.8001){
		return ($self->QueryOld(@_));
	}else{
		return ($self->QueryNew(@_));
	}
}



## Destroy ########################################
## log off remedy gracefully and destroy object
sub Destroy {
	my $self = shift();
    ARS::ars_Logoff($self->{ctrl}) if exists($self->{ctrl});
	$self = undef;
	return (1);
}




## True for perl include ##########################
1;



__END__

## AutoLoaded Methods




## CheckFields #####################################
## check the length of each presented field value
## against the remedy field's length in the config
## if we find that we don't have the schema or field
## in the config, refresh it. If we have TruncateOK
## truncate the field values to the remedy field
## length without error. Translate enum values
## to their integers. If we have errors, return
## astring containing (all of) them. If we don't
## have errors return undef with errstr "ok".
## If we have real errors, return undef with the
## errstr on errstr.
## new for 1.06: convert date, datetime & time_of_day
## values to integers of seconds (which the API wants,
## and will not do for you).
sub CheckFields {
	my ($self, %p) = @_;
	my $errors = ();

	#both Fields and Schema are required
	foreach ('Fields', 'Schema'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "CheckFields: " . $_ . " is a required option";
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#set object's default TruncateOK if not set on arg list
	$p{'TruncateOK'} = $self->{'TruncateOK'} if (! exists($p{'TruncateOK'}));

	#if we don't "know" the schema
	exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {

		#if we have 'ReloadConfigOK' in the object ... go for it
		if ($self->{'ReloadConfigOK'} > 0){
			$self->{'staleConfig'} = 1;
			warn("CheckFields: reloading stale config for unknown schema: " . $p{'Schema'}) if $self->{'Debug'};
			$self->LoadARSConfig() || do {
				$self->{'errstr'} = "CheckFields: can't reload config " . $self->{'errstr'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return(undef);
			};
			#if we didn't pick up the schema, barf
			exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {
				$self->{'errstr'} = "CheckFields: I don't know the schema: " . $p{'Schema'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}
	};

	#examine each field for length, enum, datetime & currency conversion
	foreach my $field (keys %{$p{'Fields'}}){

		#make sure we "know" the field
		exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}) || do {

			#if we have 'ReloadConfigOK' in the object ... go for it
			if ($self->{'ReloadConfigOK'} > 0){
				$self->{'staleConfig'} = 1;
				warn("CheckFields: reloading stale config for unknown field: " . $p{'Schema'} . "/" . $field) if $self->{'Debug'};
				$self->LoadARSConfig() || do {
					$self->{'errstr'} = "CheckFields: can't reload config " . $self->{'errstr'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return(undef);
				};
				#if we didn't pick up the field, barf
				exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}) || do {
					$self->{'errstr'} = "CheckFields: I don't know the field: " . $field . " in the schema: " . $p{'Schema'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
			}
		};

		#1.06 hotness: check and convert datetime, date & time_of_day
		if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'dataType'} eq "time"){

			##straight up epoch conversion, son (if it's not already) <-- 1.09 fixes this regex
			if (($p{'Fields'}->{$field} !~/^\d{1,10}$/) && ($p{'Fields'}->{$field} !~/^\s*$/)){
				my $epoch = str2time($p{'Fields'}->{$field}) || do {
					$errors .= "CheckFields epoch conversion: cannot convert datetime value: " . $p{'Fields'}->{$field};
					next;
				};
				$p{'Fields'}->{$field} = $epoch;
			}

		}elsif($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'dataType'} eq "date"){

			## 1.23 changes -- accept 10 digit integer epoch, and move the BC math out of the conversion block

			##the number of days elapsed since 1/1/4713, BCE (ya rly)
			##note: this will only work with dates > 1 BCE. (sorry, historians with remedy systems).
			if (($p{'Fields'}->{$field} !~/^\d{1,10}$/) && ($p{'Fields'}->{$field} !~/^\s*$/)){
				my $epoch = str2time($p{'Fields'}->{$field}) || do {
					$errors .= "CheckFields epoch conversion: cannot convert datetime value: " . $p{'Fields'}->{$field};
					next;
				};
				$p{'Fields'}->{$field} = $epoch;
			}
			my $tmpDate = parseInterval(seconds => $p{'Fields'}->{$field});
			$p{'Fields'}->{$field} = ($tmpDate->{'days'} + 2440588);


		}elsif($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'dataType'} eq "time_of_day"){

			##the number of seconds since midnight
			##we are going to accept one string format: hh:mm:ss AM/PM
			##otherwise you need to send your own int value
			$p{'Fields'}->{$field} =~s/\s+//g;
			if ($p{'Fields'}->{$field} =~/(\d{1,2}):(\d{1,2}):(\d{1,2})\s*(A|P)*/i){
				## we got hh:mm:ss A/P
				my ($hours, $minutes, $seconds, $ampm) = ($1, $2, $3, $4);

				## if we're in am, the hour must be < 12 (and if it's 12, that's really 0)
				## if we're in pm, the hour must be < 11
				## if we don't have an ampm, then the hour must be < 23
				## minutes and seconds must be < 60 of course.

				#handle hours
				if ($ampm =~/^a$/i){
					if ($hours > 12){
						## ERROR: out of range hour value
						$errors .= "CheckFields time-of-day conversion: hour out of range for AM";
						next;
					}elsif ($hours == 12){
						$hours = 0;
					}
				}elsif ($ampm =~/^p$/i){
					if ($hours > 11){
						## ERROR: out of range hour value
						$errors .= "CheckFields time-of-day conversion: hour out of range for PM";
						next;
					}else{
						$hours += 12;
					}
				}elsif ($ampm =~/^\s*$/){
					if ($hours > 23){
						## ERROR: out of range hour value
						$errors .= "CheckFields time-of-day conversion: hour out of range for 24 hour notation";
						next;
					}
				}
				$hours = $hours * 60 * 60;
				#handle minutes
				if ($minutes > 60){
					## ERROR: out of range minutes value
					$errors .= "CheckFields time-of-day conversion: minute value out of range";
					next;
				}else{
					$minutes = $minutes * 60;
				}
				#handle seconds
				if ($seconds > 60){
					## ERROR: out of range seconds value
					$errors .= "CheckFields time-of-day conversion: seconds value out of range";
					next;
				}

				#here it is muchacho!
				$p{'Fields'}->{$field} = $hours + $minutes + $seconds;

			}elsif($p{'Fields'}->{$field} =~/^(\d{1,5})$/){
				## we got an integer
				my $seconds = $1;
				if ($seconds > 86400){
					## ERROR: out of range integer value
					$errors .= "CheckFields time-of-day: out of range integer second value";
					next;
				}else{
					$p{'Fields'}->{$field} = $seconds;
				}
			}else{
				## ERROR: we have no idea what this is but the API isn't gonna like it
				$errors .= "CheckFields time-of-day: unparseable time-of-day string";
				next;
			}

		## 1.08 hotness: handle currency conversion
		}elsif($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'dataType'} eq "currency"){

			## if the user sent us a hash, we're just gonna trust they know what they're up to
			if (ref($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'dataType'}) ne "HASH"){

				## who gives a f*** about an oxford comma?
				## (yes I know that's not what this is, but I just wanted to drop that line so bad)
				$p{'Fields'}->{$field} =~s/,//g;

				#yeah and any kind of whitespace whatsoever gotta go too ...
				$p{'Fields'}->{$field} =~s/\s//g;

				## ok ... so ... look. 99% of the time this is gonna be USD.
				## so I'm gonna start by just looking for that. If we don't find it, then it gets interesting.
				if ($p{'Fields'}->{$field} =~/^\$/){
					$p{'Fields'}->{$field} =~s/\$//g;
					my $value = ();
					foreach my $chr (split(//, $p{'Fields'}->{$field})){
						if (($chr =~/\d/) || ($chr =~/\./)){ $value .= $chr; }
					}
					$p{'Fields'}->{$field} = {
						'conversionDate' => time(),
						'currencyCode'	 => "USD",
						'value'		 => $value,
						'funcList'	 => [ {'currencyCode' => "USD", 'value' => $value } ]
					};
				}else{
					## ok, it ain't a dollar.
					## let's start by separating the prefix from the value
					## we'll dumbly presume that anything which ain't a digit or a dot (or whitespace) is the prefix
					my @prefix = (); my $value = ();
					foreach my $chr (split(//, $p{'Fields'}->{$field})){
						if (($chr =~/\d/) || ($chr =~/\./)){
							$value .= $chr;
						}elsif ($chr !~/^\s*$/){
							push(@prefix, ord($chr));
						}
					}
					#this ain't pretty
					my @matches = ();
					foreach my $currCode(keys (%currency_codes)){
						## check for length match
						if ($#{$currency_codes{$currCode}->{'ascii_prefix_sequence'}} == $#prefix){
							my $idx = 0; my $match = 0;
							foreach my $chr (@prefix){
								if ($chr == $currency_codes{$currCode}->{'ascii_prefix_sequence'}->[$idx]){ $match = 1; }else{ $match = 0; }
								$idx ++;
							}
							if ($match == 1){
								push(@matches, $currCode);
								if ((exists($currency_codes{$currCode}->{'match_preference'})) && ($currency_codes{$currCode}->{'match_preference'} == 1)){ last; }
							}
						}
					}
					if ($#matches >= 0){
						#first pass ... if we have one with the match_preference, we'll use that ...
						my $found = 0;
						foreach my $match (@matches){
							if ((exists($currency_codes{$match}->{'match_preference'})) && ($currency_codes{$match}->{'match_preference'} == 1)){
								warn ("[CheckFields (currency)] identified '" . $p{'Fields'}->{$field} . "' as " . $currency_codes{$match}->{'name'} . " (" . $match . ")") if ($self->{'Debug'});
								$p{'Fields'}->{$field} = {
									'conversionDate' => time(),
									'currencyCode'	 => $match,
									'value'		 => $value,
									'funcList'	 => [ {'currencyCode' => $match, 'value' => $value} ]
								};
								$found = 1;
								last;
							}
						}
						#second pass ... just take the first one
						if ($found == 0){
							my $match = shift(@matches);
							warn ("[CheckFields (currency)] identified '" . $p{'Fields'}->{$field} . "' as " . $currency_codes{$match}->{'name'} . " (" . $match . ")") if ($self->{'Debug'});
							$p{'Fields'}->{$field} = {
								'conversionDate' => time(),
								'currencyCode'	 => $match,
								'value'		 => $value
							};
						}
					}else{
						#unidentifiable currency
						$errors .= "CheckFields (currency): cannot identify currency for field: " . $field . " (" . $p{'Fields'}->{$field} . ")";
						next;
					}
				}
			}
		}

		#1.06 hotness: convert diary fields to strings. This is useful for MergeTicket where we're trying
		#to write an entire diary field at once rather than insert an entry, which the API will do for us
		if (
			($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'dataType'} eq "diary") &&
			(ref($p{'Fields'}->{$field}) eq "ARRAY")
		){
			$p{'Fields'}->{$field} = $self->EncodeDBDiary(Diary => $p{'Fields'}->{$field}) || do {
				$errors .= "CheckFields diary conversion: " . $self->{'errstr'};
				next;
			};
		}

		#check length (GAH!! 1.08 fixes inverted logic here)
		if (
			( exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'length'}) ) &&
			( $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'length'} > 0 ) &&
			( length($p{'Fields'}->{$field}) > $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'length'} )
		){
			#field is too long
			if ($p{'TruncateOK'} > 0){
				$p{'Fields'}->{$field} = substr($p{'Fields'}->{$field}, 0, $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'length'});
			}else{
				$errors .= "CheckFieldLengths: " . $field . "too long (max length is ";
				$errors .= $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'length'} . ")\n";
				next;
			}
		}

		#check / translate enum
		if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'enum'} > 0){

			#if the value is given as the enum
			#the thought occurs that some asshat will make an enum field where the values are integers.
			#but for now, whatever ... "git-r-done"
			if ($p{'Fields'}->{$field} =~/^\d+$/){

			        #if it's a customized enum list ...
			        if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'enum'} == 2){

                                        #make sure we know it (enum is the hash value, string literal is the key)
                                        my $found = 0;
                                        foreach my $chewbacca (keys %{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'vals'}}){
                                                if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'vals'}->{$chewbacca} eq $p{'Fields'}->{$field}){
                                                        $found = 1;
                                                        last;
                                                }
                                        }
                                        if ($found == 0){
                                                $errors .= "CheckFieldLengths: " . $field . " enum value is not known (custom enum list)\n";
                                                next;
                                        }

			        #if it's a vanilla linear enum list ...
			        }else{
                                        #make sure the enum's not out of range
                                        if (
                                                ($p{Fields}->{$field} < 0) ||
                                                ($p{Fields}->{$field} > $#{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'vals'}})
                                        ){
                                                $errors .= "CheckFieldLengths: " . $field . " enum is out of range\n";
                                                next;
                                        }
                                }

			#if the value is given as the string (modified for 1.031)
			}elsif ($p{'Fields'}->{$field} !~/^\s*$/){

			        #if it's a custom enum list ...
			        if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'enum'} == 2){
			                #translate it (custom enum lists do not enjoy case-insensitive matching this go-round)
			                if (exists ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'vals'}->{$p{'Fields'}->{$field}})){
			                        $p{'Fields'}->{$field} = $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'vals'}->{$p{'Fields'}->{$field}};
			                }else{
			                        $errors .= "CheckFieldLengths: " . $field . " given value does not match any enumerated value for this field (custom enum list)\n";
			                        next;
                                        }

                                #if its not ...
                                }else{
                                        #translate it
                                        my $cnt = 0; my $found = 0;
                                        foreach my $val (@{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field}->{'vals'}}){
						if (($p{'Fields'}->{$field} =~/^$val$/i) || ($p{'Fields'}->{$field} eq $val)){ $p{'Fields'}->{$field} = $cnt; $found = 1; last; }
                                                $cnt ++;
                                        }

                                        #if we didn't find it
                                        if ($found != 1){
                                                $errors .= "CheckFieldLengths: " . $field . " given value does not match any enumerated value for this field\n";
                                                next;
                                        }
                                }
			}
		}
	}

	#if we had errors, return those
	return ($errors) if ($errors);

	#if we didn't have any errors, return undef with "ok"
	$self->{'errstr'} = "ok";
	return (undef);
}


## PushFields #####################################
## aka 'CreateOrUpdate'. This is an perl analog
## of the ARS "Push Fields" action.
## inputs:
##	Schema
##	Fields
##	QBE
##	NoMatchAction 	      => "Create" | "Error"
##	MultipleMatchAction   => "UpdateFirst", "UpdateAll", "Error"
##	MatchAction	      => "Update", "Error", "Nothing"
## output:
##	{
##		'records'	=> [array,of,records],
##		'disposition'	=> "created" | "updated" | "matched"
##	}
sub PushFields {
	my ($self, %p) = @_;

	##
	## INPUT VALIDATION
	##

	#Fields, Schema & QBE are required
	foreach ('Fields', 'Schema', "QBE"){
		if (! exists($p{$_})){
			$self->{'errstr'} = "PushFields: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#default options
	if ($p{'NoMatchAction'} =~/^\s*$/){ $p{'NoMatchAction'} = "Create"; }
	if ($p{'MultipleMatchAction'} =~/^\s*$/){ $p{'MultipleMatchAction'} = "UpdateFirst"; }
	if ($p{'MatchAction'} =~/^\s*$/){ $p{'MatchAction'} = "Update"; }
	$p{'TruncateOK'} = $self->{'TruncateOK'} if (! exists($p{'TruncateOK'}));

	#validate option values
	if ($p{'NoMatchAction'} =~/^create$/i){
		$p{'NoMatchAction'} = "Create";
	}elsif ($p{'NoMatchAction'} =~/^error$/i){
		$p{'NoMatchAction'} = "Error";
	}else{
		$self->{'errstr'} = "PushFields: unknown value on 'NoMatchAction' argument";
		warn($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}
	if ($p{'MultipleMatchAction'} =~/^updatefirst$/i){
		$p{'MultipleMatchAction'} = "UpdateFirst";
	}elsif ($p{'MultipleMatchAction'} =~/^updateall$/i){
		$p{'MultipleMatchAction'} = "UpdateAll";
	}elsif ($p{'MultipleMatchAction'} =~/^error$/i){
		$p{'MultipleMatchAction'} = "Error";
	}else{
		$self->{'errstr'} = "PushFields: unknown value on 'MultipleMatchAction' argument";
		warn($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}
	if ($p{'MatchAction'} =~/^update$/i){
		$p{'MatchAction'} = "Update";
	}elsif ($p{'MatchAction'} =~/^error$/i){
		$p{'MatchAction'} = "Error";
	}elsif ($p{'MatchAction'} =~/^nothing$/i){
		$p{'MatchAction'} = "Nothing";
	}else{
		$self->{'errstr'} = "PushFields: unknown value on 'MatchAction' argument";
		warn($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}
	if ($p{'AlternateSortOrder'} =~/^createdateasc/i){
		$p{'AlternateSortOrder'} = "CreateDateAscending";
	}elsif ($p{'AlternateSortOrder'} =~/^createdatedesc/i){
		$p{'AlternateSortOrder'} = "CreateDateDescending";
	}elsif ($p{'AlternateSortOrder'} =~/^modifieddateasc/i){
		$p{'AlternateSortOrder'} = "ModifiedDateAscending";
	}elsif ($p{'AlternateSortOrder'} =~/^modifieddatedesc/i){
		$p{'AlternateSortOrder'} = "ModifiedDateDescending";
	}elsif ($p{'AlternateSortOrder'} !~/^\s*$/){
		$self->{'errstr'} = "PushFields: unknown value on 'AlternateSortOrder' argument";
		warn($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}

	#make sure we know the schema
	if (! exists($self->{'ARSConfig'}->{$p{'Schema'}})){
		$self->{'errstr'} = "PushFields: unknown 'Schema': " . $p{'Schema'};
		warn($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}

	#identify fields 1, 3, & 6 on this schema
	my $field_one = (); my $field_three = (); my $field_six = ();
	foreach my $ft (keys (%{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}})){
		if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$ft}->{'id'} == 1){
			$field_one = $ft;
		}elsif ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$ft}->{'id'} == 3){
			$field_three = $ft;
		}elsif ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$ft}->{'id'} == 6){
			$field_six = $ft;
		}
		if (($field_one !~/^\s*$/) && ($field_three !~/^\s*$/) && ($field_six !~/^\s*$/)){ last; }
	}
	#we can't do this if we didn't find field 1
	if ($field_one =~/^\s*$/){
		$self->{'errstr'} = "PushFields: cannot identify field with ID '1' (entry_id) on this schema: " . $p{'Schema'};
		warn ($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}
	#if alternate sort order is specified then we can't do it without 3 & 6 too ..
	if ($p{'AlternateSortOrder'} !~/^\s*$/){
		if ($field_three =~/^\s*$/){
			$self->{'errstr'} = "PushFields: cannot identify field with ID '3' (create_date) on this schema: " . $p{'Schema'};
			warn ($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}
		if ($field_six =~/^\s*$/){
			$self->{'errstr'} = "PushFields: cannot identify field with ID '6' (modified_date) on this schema: " . $p{'Schema'};
			warn ($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}
	}

	##
	## doin' the thang ...
	##


	#step 1: identify existing record(s) or lack thereof
	my $records_found = 1;
	my $previous_flag = $self->{'DateTranslate'};
	$self->{'DateTranslate'} = 0;
	my $matches = $self->Query(
		Schema	=> $p{'Schema'},
		Fields	=> [ $field_one, $field_three, $field_six ],
		QBE	=> $p{'QBE'}
	) || do {
		#if we legitimately didn't find any ...
		if ($self->{'errstr'} =~/no matching records$/){
			$records_found = 0;
			warn("PushFields: no records match qualification") if ($self->{'Debug'});
		}else{
			#Houston, we have a problem ...
			$self->{'errstr'} = "PushFields: cannot execute query for existing record: " . $self->{'errstr'};
			warn($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}
	};
	$self->{'DateTranslate'} = $previous_flag;
	if ($records_found == 0){

		## handle no match actions
		if ($p{'NoMatchAction'} eq "Error"){
			$self->{'errstr'} = "PushFields: no records match qualification and 'MatcNoMatchAction' is set to " . '"Error"';
			warn($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}else{

			## go make one
			my $entry_id = $self->CreateTicket(
				Schema			=> $p{'Schema'},
				Fields			=> $p{'Fields'},
				JoinFormPostSubmitQuery	=> $p{'JoinFormPostSubmitQuery'}
			) || do {
				$self->{'errstr'} = "PushFields: cannot create ticket: " . $self->{'errstr'};
				warn($self->{'errstr'}) if ($self->{'Debug'});
				return(undef);
			};
			warn("PushFields: created " . $entry_id . " on " . $p{'Schema'}) if ($self->{'Debug'});
			return({
				'records' 	=> [ $entry_id ],
				'disposition'	=> "created"
			});
		}

	}else{

		## handle match errors
		if (($#{$matches} > 0) && ($p{'MultipleMatchAction'} eq "Error")){
			$self->{'errstr'} = "PushFields: " . ($#{$matches} + 1) . " records match qualification and 'MultipleMatchAction' is set to " . '"Error" matching records: ';
			foreach my $t(@{$matches}){ $self->{'errstr'} .= " " . $t->{$field_one}; }
			warn($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}elsif ($p{'MatchAction'} eq "Error"){
			$self->{'errstr'} = "PushFields: " . ($#{$matches} + 1) . " records match qualification and 'MatchAction' is set to " . '"Error"';
			warn($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}elsif ($p{'MatchAction'} eq "Nothing"){
			my @matched = ();
			foreach my $t (@{$matches}){ push(@matched, $t->{$field_one}); }
			return({
				'records'	=> \@matched,
				'disposition'	=> "matched"
			});
		}

		## alternate sort order
		if     ($p{'AlternateSortOrder'} eq "CreateDateAscending"){
			warn ("PushFields: AlternateSortOrder is CreateDateAscending") if ($self->{'Debug'});
			@{$matches} = sort {$a->{$field_three} <=> $b->{$field_three}} @{$matches};
		}elsif ($p{'AlternateSortOrder'} eq "CreateDateDescending"){
			warn ("PushFields: AlternateSortOrder is CreateDateDescending") if ($self->{'Debug'});
			@{$matches} = sort {$b->{$field_three} <=> $a->{$field_three}} @{$matches};
		}elsif ($p{'AlternateSortOrder'} eq "ModifiedDateAscending"){
			warn ("PushFields: AlternateSortOrder is ModifiedDateAscending") if ($self->{'Debug'});
			@{$matches} = sort {$a->{$field_six} <=> $b->{$field_six}} @{$matches};
		}elsif ($p{'AlternateSortOrder'} eq "ModifiedDateDescending"){
			warn ("PushFields: AlternateSortOrder is ModifiedDateDescending") if ($self->{'Debug'});
			@{$matches} = sort {$b->{$field_six} <=> $a->{$field_six}} @{$matches};
		}

		## REAL TEMP
		if ($self->{'Debug'}){
			warn ("PushFields: echoing sort order ...");
			my $ord = 0;
			foreach my $t (@{$matches}){
				$ord ++;
				warn ("\t[" . $ord . "]: " . $t->{$field_one} . " / " . gmtime($t->{$field_three}) . " / " . gmtime($t->{$field_six}));
			}
		}

		## get to updatin' ...
		my $cnt = 0; my @records_updated = ();
		foreach my $match (@{$matches}){
			$cnt ++;
			$self->ModifyTicket(
				Schema	=> $p{'Schema'},
				Fields	=> $p{'Fields'},
				Ticket	=> $match->{$field_one}
			) || do {
				$self->{'errstr'} = "PushFields: cannot modify record " . $cnt . " of " . ($#{$matches} + 1) . " [" . $match->{$field_one} . "]: " . $self->{'errstr'};
				warn($self->{'errstr'}) if ($self->{'Debug'});
				return(undef);
			};
			warn ("PushFields: updated record " . $cnt . " of " . ($#{$matches} + 1) . " [" . $match->{$field_one} . "]") if ($self->{'Debug'});
			push (@records_updated, $match->{$field_one});
			if (($#{$matches} > 0) && ($p{'MultipleMatchAction'} eq "UpdateFirst") && ($cnt == 1)){ last; }
		}
		return ({
			'records'	=> \@records_updated,
			'disposition'	=> "updated"
		});
	}
}


## CreateTicket ###################################
## create a new ticket in the given schema with
## the given field values. return the new ticket
## number
sub CreateTicket {

	my ($self, %p) = @_;

	$self->{'_API_Message'} = ();

	#both Fields and Schema are required
	foreach ('Fields', 'Schema'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "CreateTicket: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#set object's default TruncateOK if not set on arg list
	$p{'TruncateOK'} = $self->{'TruncateOK'} if (! exists($p{'TruncateOK'}));

	#spew field values in debug
	if ($self->{'Debug'}) {
		my $str = "Field Values Submitted for new ticket in " . $p{'Schema'} . "\n";
		foreach (keys %{$p{'Fields'}}){ $str .= "\t[" . $_ . "]: " . $p{'Fields'}->{$_} . "\n"; }
		warn ($str);
	}

	#check the fields
	my $errors = $self->CheckFields( %p ) || do {
		#careful now! if we're here it's either "ok" or a "real error"
		if ($self->{'errstr'} ne "ok"){
			$self->{'errstr'} = "CreateTicket: error on CheckFields: " . $self->{'errstr'};
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	};
	## fixed this logic to return undef instead of errors on version 1.08
	if (length($errors) > 0){
		$self->{'errstr'} = "CreateTicket: error on CheckFields: " . $errors;
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	}

	#ars wants an argument list like ctrl, schema, field_name, field_value ...
	my @args = ();

	#insert field list
	foreach (keys %{$p{'Fields'}}){
		push (
			@args,
			($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'},
			$p{'Fields'}->{$_})
		);
	}

	## NEW HOTNESS (1.11)
	## join forms, baby. The API lets us submit into them, but it's only a submit at the application level
	## nothing fires off in the DB. Presumably filters catch the submit transaction and handle setting up
	## the required supporting records, yielding the new record you requested in the join form.
	## why bother with this? Because basically AST:<everything> is a join form in ITSM, and through the
	## spaghetti logic that exists therein, the AST:* forms are apparently the *only* supported way to
	## shoehorn data into CMDB manually. Shoehorning data into CMDB manually, as it turns out, is like
	## pretty much what you're going to be doing for the rest of your career unless you're in the sadly
	## dwindling "custom remedy development" sceene.
	##
	## and so in the service of squeezing another ounce of juice out of this dying product,
	## I present unto you ... support for join forms on the CreateTicket call ...
	my $entry_id = ();
	$entry_id = ARS::ars_CreateEntry( $self->{'ctrl'}, $p{'Schema'}, @args ) || do {

		## echo the api message
		my $tmp = $ARS::ars_errstr;
		if ($tmp !~/^\s*$/){
			warn("API Message: " . $ARS::ars_errstr) if ($self->{'Debug'});
			$self->{'_API_Message'} = $ARS::ars_errstr;
		}

		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("CreateTicket: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "CreateTicket: failed reload stale login: " . $self->{'errstr'};
				warn ($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
			#try it again
			$entry_id = ARS::ars_CreateEntry( $self->{'ctrl'}, $p{'Schema'}, @args ) || do {
				$self->{'errstr'} = "CreateTicket: can't create ticket in: " . $p{'Schema'} . " / " . $ARS::ars_errstr;
				return (undef);
				warn ($self->{'errstr'}) if $self->{'Debug'};
			};

		#if it was a join form ...
		}elsif ((exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'_schema_info'})) && ($self->{'ARSConfig'}->{$p{'Schema'}}->{'_schema_info'}->{'schemaType'} =~/^join/i)){

			if ($self->{'OverrideJoinSubmitQuery'} == 1){
				$self->{'errstr'} = "CreateTicket: submit to join form, post-submit query for ars_CreateEntry result is disabled in config. returning undef (though this call may have succeeded)";
				warn ($self->{'errstr'}) if ($self->{'Debug'});
				return(undef)
			}

			warn ("[CreateTicket] submit to join form, querying for ars_CreateEntry result ...") if ($self->{'Debug'});

			## just build a dumb qualification based on all the fields (of the right type) that were sent in
			my $QBE_str = ();
			if ($p{'JoinFormPostSubmitQuery'} =~/^\s*$/){
				my @QBE = ();
				foreach my $qt (keys %{$p{'Fields'}}){
					if (
						(exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'})) &&
						(
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^time$/i) ||
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^date$/i) ||
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^time_of_day$/i) ||
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^integer$/i) ||
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^real$/i) ||
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^decimal$/i) ||
							($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^enum$/i) ||
							(
								($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^char$/i) &&
								($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'length'} > 0)
							)
						)
					){

						#skip display-only fields
						if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'entry_mode'} eq "display-only"){ next; }

						#replace "" with $NULL$
						my $fieldvalue = $p{'Fields'}->{$qt};
						if ($fieldvalue =~/^\s*$/){ $fieldvalue = '$NULL$'; }

						#no single-quotes on enum integer literals
						if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'dataType'} =~/^enum$/i){
							push (@QBE, "'" . $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'id'} . "' = " . $fieldvalue);
						#otherwise let 'er rip
						}else{
							push (@QBE, "'" . $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$qt}->{'id'} . "' = " . '"' . $fieldvalue . '"');
						}
					}
				}
				$QBE_str = join  (" AND ", @QBE);
			}else{
				$QBE_str = $p{'JoinFormPostSubmitQuery'};
			}

			## identify the name of field 1 and 3 in this schema (sheesh!)
			my $field_one = (); my $field_three = ();
			foreach my $ft (keys (%{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}})){
				if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$ft}->{'id'} == 1){
					$field_one = $ft;
				}elsif ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$ft}->{'id'} == 3){
					$field_three = $ft;
				}
				if (($field_one !~/^\s*$/) && ($field_three !~/^\s*$/)){ last; }
			}
			if ($field_one =~/^\s*$/){
				$self->{'errstr'} = "CreateTicket: submit to join form *may* have failed. Cannot query for ars_CreateEntry result. Cannot identify field 1 for this schema";
				warn ($self->{'errstr'}) if ($self->{'Debug'});
				return(undef);
			}
			if ($field_three =~/^\s*$/){
				$self->{'errstr'} = "CreateTicket: submit to join form *may* have failed. Cannot query for ars_CreateEntry result. Cannot identify field 3 for this schema";
				warn ($self->{'errstr'}) if ($self->{'Debug'});
				return(undef);
			}



			## query for it
			my $date_translate_state = $self->{'DateTranslate'};
			$self->{'DateTranslate'} = 0;
			my $tmp = $self->Query(
				Schema	=> $p{'Schema'},
				Fields	=> [ $field_one, $field_three ],
				QBE	=> $QBE_str
			) || do {
				$self->{'errstr'} = "CreateTicket: submit to join form *may* have failed. Cannot query for ars_CreateEntry result: " . $self->{'errstr'};
				warn ($self->{'errstr'}) if ($self->{'Debug'});
				return(undef);
			};
			$self->{'DateTranslate'} = $date_translate_state;

			## lawdy, if we got back more than one ...
			if ($#{$tmp} > 0){

				## I guess you know ... sort 'em and take the most recent.
				@{$tmp} = sort{ $b->{$field_three} <=> $a->{$field_three} } @{$tmp};
				my $the_one = shift(@{$tmp});
				my $now = time();
				my $interval = ($now - $the_one->{$field_three});
				my $interval_str = parseInterval(
					seconds	=> $interval,
					Small	=> 1
				);
				warn ("CreateTicket: submit to join form: found " . ($#{$tmp} + 1) . " results matching submission, returning most recent: " . $the_one->{$field_one} . " (created " . $interval_str . " ago)") if ($self->{'Debug'});
				$entry_id = $the_one->{$field_one};

			}else{
				warn ("CreateTicket: submit to join form: identified: " . $tmp->[0]->{$field_one}) if ($self->{'Debug'});
				$entry_id = $tmp->[0]->{$field_one};
			}
		}else{
			## either it was a join form and the config is fouled or it wasn't a join form, either way it's time to return undef
			$self->{'errstr'} = "CreateTicket: create operation failed with error: " . $ARS::ars_errstr;
			warn ($self->{'errstr'}) if ($self->{'Debug'});
			return(undef);
		}
	};

	## NOTE TO SELF: put something out here to catch passive API errors
	if (($entry_id !~/^\s*$/) && ($ARS::ars_errstr !~/^\s*$/)){
		warn ("CreateTicket: success with passive API message: " . $ARS::ars_errstr) if ($self->{'Debug'});
		$self->{'_API_Message'} = $ARS::ars_errstr;
	}

	#back at ya, baby!
	return ($entry_id);
}




## ModifyTicket ###################################
sub ModifyTicket{

	my ($self, %p) = @_;

	#Fields, Schema & Ticket are required
	foreach ('Fields', 'Schema', 'Ticket'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "ModifyTicket: " . $_ . " is a required option";
			return (undef);
		}
	}

	#set object's default TruncateOK if not set on arg list
	$p{'TruncateOK'} = $self->{'TruncateOK'} if (! exists($p{'TruncateOK'}));

	#spew field values in debug
	if ($self->{'Debug'}) {
		my $str = "Field Values To Change in " . $p{'Schema'} . "/" . $p{'Ticket'} . "\n";
		foreach (keys %{$p{'Fields'}}){ $str .= "\t[" . $_ . "]: " . $p{'Fields'}->{$_} . "\n"; }
		warn ($str);
	}

	#check the fields
	my $errors = ();
	$errors = $self->CheckFields( %p ) || do {
		#careful now! if we're here it's either "ok" or a "real error"
		if ($self->{'errstr'} ne "ok"){
			$self->{'errstr'} = "ModifyTicket: error on CheckFields: " . $errors . " / " . $self->{'errstr'};
			return (undef);
		}
	};
	if (length($errors) > 0){
		$self->{'errstr'} = "ModifyTicket: error on CheckFields: " . $errors . " / " . $self->{'errstr'};
		return (undef);
	}

	#ars wants an argument list like ctrl, schema, ticket_no, field, value ...
	my @args = ();

	#insert field list
	foreach (keys %{$p{'Fields'}}){
		push (
			@args,
			($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'},
			$p{'Fields'}->{$_})
		);
	}

	#it's rockin' like dokken
	ARS::ars_SetEntry( $self->{'ctrl'}, $p{'Schema'}, $p{'Ticket'}, 0, @args ) || do {

		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("ModifyTicket: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "ModifyTicket: failed reload stale login: " . $self->{'errstr'};
				return (undef);
			};
			#try it again
			ARS::ars_SetEntry( $self->{'ctrl'}, $p{'Schema'}, $p{'Ticket'}, @args ) || do {
				$self->{'errstr'} = "ModifyTicket: can't modify : " . $p{'Schema'} . " / " .
				                    $p{'Ticket'} . ": " . $ARS::ars_errstr;
				return (undef);
			};
		}
		$self->{'errstr'} = "ModifyTicket: can't modify : " . $p{'Schema'} . " / " .
				            $p{'Ticket'} . ": " . $ARS::ars_errstr;
		return (undef);
	};

	#the sweet one-ness of success!
	return (1);
}




## DeleteTicket ###################################
## delete the ticket from remedy
## obviously if your user dosen't have admin rights
## this is going to fail.
sub DeleteTicket {
	my ($self, %p) = @_;

	#both Fields and Schema are required
	foreach ('Ticket', 'Schema'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "DeleteTicket: " . $_ . " is a required option";
			return (undef);
		}
	}

	#dirty deeds, done ... well dirt cheap, really
	ARS::ars_DeleteEntry( $self->{'ctrl'}, $p{'Schema'}, $p{'Ticket'} ) || do {

		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("DeleteTicket: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "DeleteTicket: failed reload stale login: " . $self->{'errstr'};
				return (undef);
			};
			#try it again
			ARS::ars_DeleteEntry( $self->{'ctrl'}, $p{'Schema'}, $p{'Ticket'} ) || do {
				$self->{'errstr'} = "DeleteTicket: can't delete: " . $p{'Schema'} . " / " .
				                    $p{'Ticket'} . ": " .$ARS::ars_errstr;
				return (undef);
			};
		}
		$self->{'errstr'} = "DeleteTicket: can't delete: " . $p{'Schema'} . " / " .
				            $p{'Ticket'} . ": " .$ARS::ars_errstr;
		return (undef);
	};

	#buh bye, now!
	return (1);
}


## EncodeDBDiary #####################################
## this is the inverse of ParseDBDiary. This will take
## a perl data structure, the likes of which is returned
## by ParseDBDiary or Query (when returning a diary field)
## and it will output a formatted text field suitable for
## manually inserting directly into a database table,
## also for setting a diary field with MergeTicket (though
## Remedy::ARSTools will call this for you out of CheckFields
## if you send an array of hashes on a diary field value).
sub EncodeDBDiary {

	## as with ParseDBDiary, this is also exported procedural
	## for your git-r-done pleasure
	my ($self, %p) = ();
	if (ref($_[0]) eq "Remedy::ARSTools"){
		#oo mode
		($self, %p) = @_;
	}else{
		#procedural mode
		$self = bless({});
		%p = @_;
	}

	my ($record_separator, $meta_separator) = (chr(03), chr(04));
	my @records = ();

	#Diary is the only required option and it must be an array of hashes
	#each containing 'timestamp', 'user' and 'value
	exists($p{'Diary'}) || do {
		$errstr = $self->{'errstr'} = "EncodeDBDiary: 'Diary' is a required option";
		warn($self->{'errstr'}) if $self->{'debug'};
		return (undef);
	};
	if (ref($p{'Diary'}) ne "ARRAY"){
		$errstr = $self->{'errstr'} = "EncodeDBDiary: 'Diary' must be an ARRAY reference";
		warn($self->{'errstr'}) if $self->{'debug'};
		return (undef);
	}

	#I guess we otter check that each array element is a hash ref with the required data ...
	foreach my $entry (@{$p{'Diary'}}){
		if (ref($entry) ne "HASH"){
			$errstr = $self->{'errstr'} = "EncodeDBDiary: 'Diary' must be an ARRAY or HASH references";
			warn($self->{'errstr'}) if $self->{'debug'};
			return (undef);
		}
		foreach ('timestamp', 'user', 'value'){
			if (! exists($entry->{$_})){
				$errstr = $self->{'errstr'} = "EncodeDBDiary: 'Diary' contains incomplete records!";
				warn($self->{'errstr'}) if $self->{'debug'};
				return (undef);
			}
		}
	}

	#let's do this ... sort the thang in reverse chronological order, build a string for each
	#entry then join the whole thang with the record separator. and return it
	@{$p{'Diary'}} = sort{ $a->{'timestamp'} <=> $b->{'timestamp'} } @{$p{'Diary'}};
	my @skrangz = ();
	foreach my $entry (@{$p{'Diary'}}){

		#if 'timestamp' is not an integer ...
		if ($entry->{'timestamp'} !~/^\d{1,10}$/){
			$entry->{'timestamp'} = str2time($entry->{'timestamp'}) || do {
				$errstr = $self->{'errstr'} = "EncodeDBDiary: contains an entry with an unparseable 'timestamp': " . $entry->{'timestamp'};
				warn($self->{'errstr'}) if $self->{'debug'};
				return (undef);
			};
		}

		my $tmp = join($meta_separator, $entry->{'timestamp'}, $entry->{'user'}, $entry->{'value'});
		push(@skrangz, $tmp);
	}
	my $big_diary_string = join($record_separator, @skrangz);
	return($big_diary_string . $record_separator); 		## <-- yeah it always sticks one at the end for some reason
}



## ParseDBDiary #####################################
## this will parse a raw ARS diary field as it appears
## in the underlying database into the same data
## structure returned ARS::getField. To refresh your
## memory, that's: a sorted array of hashes, each hash
## containing a 'timestamp','user', and 'value' field.
## The date is converted to localtime by default, to
## override, sent 1 on the -OverrideLocaltime option the
## array is sorted by date. This is a non OO version so
## that it can be called by programs which don't need to
## make an object (i.e. actually talk to a remedy server).
## If you are using this module OO, you can call the
## ParseDiary method, which is essentially an OO wrapper
## for this method. Errors are on $Remedy::ARSTools::errstr.
sub ParseDBDiary {

	#this is exported procedural, as well as an OO method
	my ($self, %p) = ();
	if (ref($_[0]) eq "Remedy::ARSTools"){
		#oo mode
		($self, %p) = @_;
	}else{
		#procedural mode
		$self = bless({});
		%p = @_;
	}

	my ($record_separator, $meta_separator) = (chr(03), chr(04));
	my @records = ();

	exists($p{'Diary'}) || do {
		$errstr = $self->{'errstr'} = "ParseDBDiary: 'Diary' is a required option";
		warn($self->{'errstr'}) if $self->{'debug'};
		return (undef);
	};

	#we expect at least 'Diary' and possibly 'ConvertDate'

	#if we got DateConversionTimeZone, sanity check it
	if ($p{'DateConversionTimeZone'} !~/^\s*$/){
		if ($p{'DateConversionTimeZone'} =~/(\+|\-)(\d{1,2})/){
			($p{'plusminus'}, $p{'offset'}) = ($1, $2);
			if ($p{'offset'} > 24){
				$self->{'errstr'} = "ParseDBDiary: 'DateConversionTimeZone' is out of range (" . $p{'DateConversionTimeZone'} . ")";
				warn ($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			}
		}else{
			$self->{'errstr'} = "ParseDBDiary: 'DateConversionTimeZone' is unparseable (" . $p{'DateConversionTimeZone'} . ")";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#it might be one record with no separator
	if ($p{'Diary'} !~/$record_separator/){

		#we need at least one meta_separator though
		if ($p{'Diary'} !~/$meta_separator/){
			$errstr = $self->{'errstr'} = "ParseDBDiary: non-null diary contains malformed record";
			warn($self->{'errstr'}) if $self->{'debug'};
			return(undef);
		};

		#otherwise, just put it on the records stack
		push (@records, $p{'Diary'});

	}else{

		#do the split
		@records = split(/$record_separator/, $p{'Diary'});

	}

	#parse the entries
	foreach (@records){
		my ($timestamp, $user, $value) = split(/$meta_separator/, $_);

		#if 'ConvertDate' and 'DateConversionTimeZone' are set, do the math
		if ($p{'ConvertDate'} > 0) {

			if ($p{'DateConversionTimeZone'} !~/^\s*$/){
				if ($p{'plusminus'} eq "+"){
					$timestamp += ($p{'offset'} * 60 * 60);
				}elsif ($p{'plusminus'} eq "-"){
					$timestamp -= ($p{'offset'} * 60 * 60);
				}
			}

			#convert that thang to GMT
			$timestamp = gmtime($timestamp);
			$timestamp .= "GMT";

			#tack on the offset if we had one
			if ($p{'DateConversionTimeZone'} !~/^\s*$/){
				$p{'offset'} = sprintf("%02d", $p{'offset'});
				$timestamp .= " " . $p{'plusminus'} . $p{'offset'} . "00";
			}
		}

		#put it back on the stack as a hash reference
		$_ = {
			'timestamp'	=> $timestamp,
			'user'		=> $user,
			'value'		=> $value
		}
	}

	#make sure we're sorted by date
	@records  = sort{ $a->{'timestamp'} <=> $b->{'timestamp'} } @records;

	#send 'em back
	return (\@records);
}



## ARSLoginOld ####################################
## for ARSPerl installs < 1.8001
sub ARSLoginOld {

	my ($self, %p) = @_;

	#return if already logged in and not marked stale
	if ( (exists($self->{'ctrl'})) && ($self->{'staleLogin'} != 1) ){ return(1); }

	#if it's a stale login, try to logoff first
	if ( (exists($self->{'ctrl'})) && ($self->{'staleLogin'} = 1) ){ ARS::ars_Logoff($self->{'ctrl'}); }

	#if we have Port, set it in the environment, otherwise delete it in the environment
	if ($self->{'Port'} =~/\d+/){ $ENV{'ARTCPPORT'} = $self->{'Port'}; }else{ delete($ENV{'ARTCPPORT'}); }

	#get a control structure
	$self->{'ctrl'} = ARS::ars_Login(
		$self->{'Server'},
		$self->{'User'},
		$self->{'Pass'}
	) || do {
		$self->{'errstr'} = "ARSLoginOld: can't login to remedy server: " . $ARS::ars_errstr;
		warn($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};

	#debug
	warn("ARSLoginOld: logged in " . $self->{'Server'} . ":" . $self->{'Port'} . " " . $self->{'User'}) if $self->{'Debug'};

	#unset stale login
	$self->{'staleLogin'} = 0;

	#it's all good baby bay bay ...
	return (1);
}




## ARSLoginNew ####################################
## for ARSperl installs >= 1.8001
sub ARSLoginNew {
my ($self, %p) = @_;

	#return if already logged in and not marked stale
	if ( (exists($self->{'ctrl'})) && ($self->{'staleLogin'} != 1) ){ return(1); }

	#if it's a stale login, try to logoff first
	if ( (exists($self->{'ctrl'})) && ($self->{'staleLogin'} = 1) ){ ARS::ars_Logoff($self->{'ctrl'}); }

	#get a control structure
	$self->{'ctrl'} = ARS::ars_Login(
		$self->{'Server'},
		$self->{'User'},
		$self->{'Pass'},
		$self->{'Language'},
		$self->{'AuthString'},
		$self->{'Port'},
		$self->{'RPCNumber'}
	) || do {
		$self->{'errstr'} = "ARSLoginNew: can't login to remedy server: " . $ARS::ars_errstr;
		warn($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};

	#debug
	warn("ARSLoginNew: logged in " . $self->{'Server'} . ":" . $self->{'Port'} . " " . $self->{'User'}) if $self->{'Debug'};

	#unset stale login
	$self->{'staleLogin'} = 0;

	#it's all good baby bay bay ...
	return (1);
}




## QueryOld #######################################
## issue a query through the ARS api using the
## QBE ("query by example") string
## NOTE: this is NOT the same thing as an SQL
## 'where' clause. Also NOTE: that this will present
## significantly more overhead than directly querying
## the database, but I presume you have your reasons ... ;-)
## do it using the pre 1.8001 argument list for ars_getListEntry
sub QueryOld {
	my ($self, %p) = @_;

	#QBE, Schema & Fields are required
	foreach ('Fields', 'Schema', 'QBE'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "QueryOld: " . $_ . " is a required option";
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#we need to make sure we 'know' the schema
	exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {

		#if we have 'ReloadConfigOK' in the object ... go for it
		if ($self->{'ReloadConfigOK'} > 0){
			$self->{'staleConfig'} = 1;
			warn("QueryOld: reloading stale config for unknown schema: " . $p{'Schema'}) if $self->{'Debug'};
			$self->LoadARSConfig() || do {
				$self->{'errstr'} = "QueryOld: can't reload config " . $self->{'errstr'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return(undef);
			};
			#if we didn't pick up the schema, barf
			exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {
				$self->{'errstr'} = "QueryOld: I don't know the schema: " . $p{'Schema'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}
	};

	#get field list translated to field_id
	my @get_list = ();
	my %revMap   = ();
	foreach (@{$p{'Fields'}}){

		#make sure we "know" the field
		exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}) || do {

			#if we have 'ReloadConfigOK' in the object ... go for it
			if ($self->{'ReloadConfigOK'} > 0){
				$self->{'staleConfig'} = 1;
				warn("QueryOld: reloading stale config for unknown field: " . $p{'Schema'} . "/" . $_) if $self->{'Debug'};
				$self->LoadARSConfig() || do {
					$self->{'errstr'} = "QueryOld: can't reload config " . $self->{'errstr'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return(undef);
				};
				#if we didn't pick up the field, barf
				exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}) || do {
					$self->{'errstr'} = "QueryOld: I don't know the field: " . $_ . " in the schema: " . $p{'Schema'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
			}
		};

		#put field_id in the get_list
		push (@get_list, $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'});

		#also make a hash based on device_id (to re-encode results)
		$revMap{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'}} = $_;
	}

	#qualify the query
	my $qual = ();
	$qual = ARS::ars_LoadQualifier($self->{'ctrl'}, $p{'Schema'}, $p{'QBE'}) || do {
		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("QueryOld: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "QueryOld: failed reload stale login: " . $self->{'errstr'};
				return (undef);
			};
			#try it again
			$qual = ARS::ars_LoadQualifier($self->{'ctrl'}, $p{'Schema'}, $p{'QBE'}) || do {
				$self->{'errstr'} = "QueryOld: can't qualify Query: " . $p{'Schema'} . " / " .
				                    $p{'QBE'} . "/" . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}
		$self->{'errstr'} = "QueryOld: can't qualify Query: " . $p{'Schema'} . " / " .
		$p{'QBE'} . "/" . $ARS::ars_errstr;
		warn($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};

	#okay now we get the list of record numbers ...
	my %tickets = ();
	(%tickets = ARS::ars_GetListEntry($self->{'ctrl'}, $p{'Schema'}, $qual, 0)) || do {
		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("QueryOld: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "QueryOld: failed reload stale login: " . $self->{'errstr'};
				return (undef);
			};
			#try it again
			(%tickets = ARS::ars_GetListEntry($self->{'ctrl'}, $p{'Schema'}, $qual, 0)) || do {
				$self->{'errstr'} = "QueryOld: can't get ticket list: " . $p{'Schema'} . " / " .
				                    $p{'QBE'} . "/" . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}

		if (! $ARS::ars_errstr){
			$self->{'errstr'} = "QueryOld: no matching records";
		}else{
			$self->{'errstr'} = "QueryOld: can't get ticket list: " . $p{'Schema'} . " / " .
			$p{'QBE'} . "/" . $ARS::ars_errstr;
		}
		warn($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};
	if ($self->{'Debug'}){
		my $num = keys(%tickets);
		warn ($num . " matching records") if $self->{'Debug'};
	}

	#and now, finally, we go and get the selected fields out of each ticket
	my @out = ();
	foreach (keys %tickets){
		my %values = ();
		(%values = ARS::ars_GetEntry($self->{'ctrl'}, $p{'Schema'}, $_, @get_list)) || do {
			#if it was an ARERR 161 (staleLogin), reconnect and try it again
			if ($ARS::ars_errstr =~/ARERR \#161/){
				warn("QueryOld: reloading stale login") if $self->{'Debug'};
				$self->{'staleLogin'} = 1;
				$self->ARSLogin() || do {
					$self->{'errstr'} = "QueryOld: failed reload stale login: " . $self->{'errstr'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
				#try it again
				(%values = ARS::ars_GetEntry($self->{'ctrl'}, $p{'Schema'}, $_, @get_list)) || do {
					$self->{'errstr'} = "QueryOld: can't get ticket fields: " . $p{'Schema'} . " / " .
										$p{'QBE'} . "/" . $_ . ": " . $ARS::ars_errstr;
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
			}
			$self->{'errstr'} = "QueryOld: can't get ticket fields: " . $p{'Schema'} . " / " .
			$p{'QBE'} . "/" . $_ . ": " . $ARS::ars_errstr;
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};

		#translate field names & enums back to human-readable
		my $converted_row_data = $self->ConvertFieldsToHumanReadable(
			Schema			=> $p{'Schema'},
			Fields			=> \%values,
			DateConversionTimeZone	=> $p{'DateConversionTimeZone'}
		) || do {
			$self->{'errstr'} = "QueryOld: can't convert data returned on API (this should not happen!): " . $self->{'errstr'};
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};

		#push it on list of results
		push (@out, $converted_row_data);

		#push it on list of results
		push (@out, \%values);
	}

	#return the list of results
	return (\@out);
}


## QueryNew #######################################
## issue a query through the ARS api using the
## QBE ("query by example") string
## NOTE: this is NOT the same thing as an SQL
## 'where' clause. Also NOTE: that this will present
## significantly more overhead than directly querying
## the database, but I presume you have your reasons ... ;-)
## do it with post 1.8001 ars_getListEntry argument list
sub QueryNew {
	my ($self, %p) = @_;

	#QBE, Schema & Fields are required
	foreach ('Fields', 'Schema', 'QBE'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "QueryNew: " . $_ . " is a required option";
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	## 1/27/2020 -- default getAttachments is false
	if (! ($p{'getAttachments'} == 1)){ $p{'getAttachments'} = 0; }

	#we need to make sure we 'know' the schema
	exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {

		#if we have 'ReloadConfigOK' in the object ... go for it
		if ($self->{'ReloadConfigOK'} > 0){
			$self->{'staleConfig'} = 1;
			warn("QueryNew: reloading stale config for unknown schema: " . $p{'Schema'}) if $self->{'Debug'};
			$self->LoadARSConfig() || do {
				$self->{'errstr'} = "QueryNew: can't reload config " . $self->{'errstr'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return(undef);
			};
			#if we didn't pick up the schema, barf
			exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {
				$self->{'errstr'} = "QueryNew: I don't know the schema: " . $p{'Schema'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}
	};

	#get field list translated to field_id
	my @get_list = ();
	my %revMap   = ();
	foreach (@{$p{'Fields'}}){

		#make sure we "know" the field
		exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}) || do {

			#if we have 'ReloadConfigOK' in the object ... go for it
			if ($self->{'ReloadConfigOK'} > 0){
				$self->{'staleConfig'} = 1;
				warn("QueryNew: reloading stale config for unknown field: " . $p{'Schema'} . "/" . $_) if $self->{'Debug'};
				$self->LoadARSConfig() || do {
					$self->{'errstr'} = "QueryNew: can't reload config " . $self->{'errstr'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return(undef);
				};
				#if we didn't pick up the field, barf
				exists($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}) || do {
					$self->{'errstr'} = "QueryNew: I don't know the field: " . $_ . " in the schema: " . $p{'Schema'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
			}
		};

		#put field_id in the get_list
		push (@get_list, $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'});

		#also make a hash based on device_id (to re-encode results)
		$revMap{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'}} = $_;
	}

	warn ("QueryNew: qualifying: [schema]: " . $p{'Schema'} . "[qbe]: " . $p{'QBE'}) if ($self->{'Debug'});

	#qualify the query
	my $qual = ();
	$qual = ARS::ars_LoadQualifier($self->{'ctrl'}, $p{'Schema'}, $p{'QBE'}) || do {
		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("QueryNew: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "QueryNew: failed reload stale login: " . $self->{'errstr'};
				return (undef);
			};
			#try it again
			$qual = ARS::ars_LoadQualifier($self->{'ctrl'}, $p{'Schema'}, $p{'QBE'}) || do {
				$self->{'errstr'} = "QueryNew: can't qualify Query: " . $p{'Schema'} . " / " .
				                    $p{'QBE'} . "/" . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}
		$self->{'errstr'} = "QueryNew: can't qualify Query: " . $p{'Schema'} . " / " .
		$p{'QBE'} . "/" . $ARS::ars_errstr;
		warn($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};

	#okay now we get the list of record numbers ...
	my %tickets = ();
	(%tickets = ARS::ars_GetListEntry($self->{'ctrl'}, $p{'Schema'}, $qual, 0, 0)) || do {
		#if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("QueryNew: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "QueryNew: failed reload stale login: " . $self->{'errstr'};
				return (undef);
			};
			#try it again
			(%tickets = ARS::ars_GetListEntry($self->{'ctrl'}, $p{'Schema'}, $qual, 0, 0)) || do {
				$self->{'errstr'} = "QueryNew: can't get ticket list: " . $p{'Schema'} . " / " .
				                    $p{'QBE'} . "/" . $ARS::ars_errstr;
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}

		if (! $ARS::ars_errstr){
			$self->{'errstr'} = "QueryNew: no matching records";
		}else{
			$self->{'errstr'} = "QueryNew: can't get ticket list: " . $p{'Schema'} . " / " .
			$p{'QBE'} . "/" . $ARS::ars_errstr;
		}
		warn($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};
	if ($self->{'Debug'}){
		my $num = keys(%tickets);
		warn ($num . " matching records") if $self->{'Debug'};
	}

	#and now, finally, we go and get the selected fields out of each ticket
	my @out = ();
	foreach my $t (keys %tickets){
		my %values = ();
		(%values = ARS::ars_GetEntry($self->{'ctrl'}, $p{'Schema'}, $t, @get_list)) || do {
			#if it was an ARERR 161 (staleLogin), reconnect and try it again
			if ($ARS::ars_errstr =~/ARERR \#161/){
				warn("QueryNew: reloading stale login") if $self->{'Debug'};
				$self->{'staleLogin'} = 1;
				$self->ARSLogin() || do {
					$self->{'errstr'} = "QueryNew: failed reload stale login: " . $self->{'errstr'};
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
				#try it again
				(%values = ARS::ars_GetEntry($self->{'ctrl'}, $p{'Schema'}, $t, @get_list)) || do {
					$self->{'errstr'} = "QueryNew: can't get ticket fields: " . $p{'Schema'} . " / " .
										$p{'QBE'} . "/" . $t . ": " . $ARS::ars_errstr;
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
			}
			$self->{'errstr'} = "QueryNew: can't get ticket fields: " . $p{'Schema'} . " / " .
			$p{'QBE'} . "/" . $t . ": " . $ARS::ars_errstr;
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};

		my $converted_row_data = $self->ConvertFieldsToHumanReadable(
			Schema					=> $p{'Schema'},
			Fields					=> \%values,
			DateConversionTimeZone	=> $p{'DateConversionTimeZone'}
		) || do {
			$self->{'errstr'} = "QueryNew: can't convert data returned on API (this should not happen!): " . $self->{'errstr'};
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};

		## handle attachments
		## 1/24/2020 -- this is not probably the best place for it
		if ($p{'getAttachments'} == 1){
			foreach my $field_name (keys (%{$converted_row_data})){
				if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'dataType'} eq "attach"){
					if (exists($converted_row_data->{$field_name}->{'origSize'}) && $converted_row_data->{$field_name}->{'origSize'} > 0){
						my $a = ARS::ars_GetEntryBLOB(
							$self->{'ctrl'},
							$p{'Schema'},
							$t,
							$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'id'},
							ARS::AR_LOC_BUFFER
						) || do {
							$self->{'errstr'} = "QueryNew: failed to retrieve attachment content (" . $p{'Schema'} . "[" . $t . "]/" . $field_name . "): " . $ARS::ars_errstr;
							warn($self->{'errstr'}) if $self->{'Debug'};
							return (undef);
						};
						$converted_row_data->{$field_name}->{'buffer'} = $a;
						$converted_row_data->{$field_name}->{'size'} = length($a);
					}
				}
			}
		}

		#push it on list of results
		push (@out, $converted_row_data);

	}

	#return the list of results
	return (\@out);
}

## MergeTicket ###################################
## just like CreateTicket, but a Merge transaction
## Fields                       list o' fields (same as CreateTicket)
## Schema                       target form for the transaction (same as CreateTicket)
## MergeCreateMode              specifies how to handle record creation if the specified entry-id (fieldid 1) value exists"
##      'Error'                 -- throw an error
##      'Create'                -- spawn new (different) entry-id value
##      'Overwrite'             -- overwrite the existing entry-id
## AllowNullFields              (default false) if set true, allows the merge transaction to bypass required non-null fields
## SkipFieldPatternCheck        (default false) if set true, allows the merge transaction to bypass field pattern checking
sub MergeTicket {

        my ($self, %p) = @_;

	#Fields, Schema, MergeMode are required
	foreach ('Fields', 'Schema', 'MergeCreateMode'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "MergeTicket: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#handle MergeMode
	my $arsMergeCode = 0;
	if ($p{'MergeCreateMode'} eq "Error"){
	        $arsMergeCode += 1;
        }elsif ($p{'MergeCreateMode'} eq "Create"){
                $arsMergeCode += 2;
        }elsif ($p{'MergeCreateMode'} eq "Overwrite"){
                $arsMergeCode += 3;
        }else{
                $self->{'errstr'} = "MergeTicket: " . $_ . " unknown Merge mode: options are Error, Create, Overwrite";
                warn ($self->{'errstr'}) if $self->{'Debug'};
                return (undef);
        }

        #handle AllowNullFields
        if ($p{'AllowNullFields'} !~/^\s*$/){
                $arsMergeCode += 1024;
        }

        #handle SkipFieldPatternCheck
        if ($p{'SkipFieldPatternCheck'} !~/^\s*$/){
                $arsMergeCode += 2048;
        }

	#set object's default TruncateOK if not set on arg list
	$p{'TruncateOK'} = $self->{'TruncateOK'} if (! exists($p{'TruncateOK'}));

	#spew field values in debug
	if ($self->{'Debug'}) {
		my $str = "Field Values Submitted for merged ticket in " . $p{'Schema'} . "\n";
		foreach (keys %{$p{'Fields'}}){ $str .= "\t[" . $_ . "]: " . $p{'Fields'}->{$_} . "\n"; }
		warn ($str);
	}

	#check the fields
	my $errors = $self->CheckFields( %p ) || do {
		#careful now! if we're here it's either "ok" or a "real error"
		if ($self->{'errstr'} ne "ok"){
			$self->{'errstr'} = "MergeTicket: error on CheckFields: " . $self->{'errstr'};
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	};
	if (length($errors) > 0){
		$self->{'errstr'} = "MergeTicket: error on CheckFields: " . $errors;
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return ($errors);
	}

	#was it over when the Germans bombed Pearl Harbor???!
	if ($self->{'doubleSecretDebug'}) {
                my $str = "field values after translation: " . $p{'Schema'} . "\n";
                foreach (keys %{$p{'Fields'}}){ $str .= "\t[" . $_ . "]: " . $p{'Fields'}->{$_} . "\n"; }
                warn ($str);
                $self->{'errstr'} = "exit for doubleSecretDebug";
                return (undef);
        }

	#ars wants an argument list like ctrl, schema, field_name, field_value ...
	my @args = ();

	#insert field list
	foreach (keys %{$p{'Fields'}}){
		push (
			@args,
			($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$_}->{'id'},
			$p{'Fields'}->{$_})
		);
	}

	#for those about to rock, we solute you!
	my $entry_id = ();
	$entry_id = ARS::ars_MergeEntry($self->{'ctrl'}, $p{'Schema'}, $arsMergeCode, @args) || do {
	        #if it was an ARERR 161 (staleLogin), reconnect and try it again
		if ($ARS::ars_errstr =~/ARERR \#161/){
			warn("MergeTicket: reloading stale login") if $self->{'Debug'};
			$self->{'staleLogin'} = 1;
			$self->ARSLogin() || do {
				$self->{'errstr'} = "MergeTicket: failed reload stale login: " . $self->{'errstr'};
				warn ($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
			#try it again
			$entry_id = ARS::ars_MergeEntry($self->{'ctrl'}, $p{'Schema'}, $arsMergeCode, @args) || do {

			        ##this thing might legitimately return null
			        if ($ARS::ars_errstr !~/^\s*$/){
                                        $self->{'errstr'} = "MergeTicket: can't merge record in: " . $p{'Schema'} . " / " . $ARS::ars_errstr;
                                        warn ($self->{'errstr'}) if $self->{'Debug'};
                                        return (undef);
                                }
			};
		} elsif ($ARS::ars_errstr !~/^\s*$/){
                        $self->{'errstr'} = "MergeTicket: can't merge record in: " . $p{'Schema'} . " / " . $ARS::ars_errstr;
                        warn ($self->{'errstr'}) if $self->{'Debug'};
                        return (undef);
                } else {
                        warn ("successful merge in overwrite mode") if $self->{'Debug'};
                        $entry_id = "overwritten";
                }
	};

	#back at ya, baby!
	return ($entry_id);
}


## ConvertFieldsToHumanReadable #################
## this takes a big hash of field_id -> value pairs
## for a given schema and:
##	1) converts all the field_id values to Field Names for the specified schema
##	2) converts integer-specified enum values to human-readable strings
##	3) converts date, datetime & time_of_day integer values to strings
##	4) converts packed diary fields to the standard diary field structure (see ParseDiary)
## required arguments:
##	'Fields'		=> a hash reference containing field_id => value pairs not unlike what comes out of ars_GetEntry
##	'Schema'		=> the name of the Schema (or "Form" in today's parlance) from whence the 'Fields' data originated
## optional arguments:
##	'DateConversionTimeZone' => number of hours offset from GMT for datetime conversion (default = 0 = GMT)
## on success return a hash reference containing the converted field list
## else undef + errstr
sub ConvertFieldsToHumanReadable {
	my ($self, %p) = @_;

	#Fields and Schema are required
	foreach ('Fields', 'Schema'){
		if (! exists($p{$_})){
			$self->{'errstr'} = "ConvertFieldsToHumanReadable: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#if we got DateConversionTimeZone, sanity check it
	if ($p{'DateConversionTimeZone'} !~/^\s*$/){
		if ($p{'DateConversionTimeZone'} =~/(\+|\-)(\d{1,2})/){
			($p{'plusminus'}, $p{'offset'}) = ($1, $2);
			if ($p{'offset'} > 24){
				$self->{'errstr'} = "ConvertFieldsToHumanReadable: 'DateConversionTimeZone' is out of range (" . $p{'DateConversionTimeZone'} . ")";
				warn ($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			}
		}else{
			$self->{'errstr'} = "ConvertFieldsToHumanReadable: 'DateConversionTimeZone' is unparseable (" . $p{'DateConversionTimeZone'} . ")";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#yeah ...
	my @month_converter = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekday_converter = qw(Sun Mon Tue Wed Thu Fri Sat);

	#make sure we 'know' the schema
	exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {

		#if we have 'ReloadConfigOK' in the object ... go for it
		if ($self->{'ReloadConfigOK'} > 0){
			$self->{'staleConfig'} = 1;
			warn("ConvertFieldsToHumanReadable: reloading stale config for unknown schema: " . $p{'Schema'}) if $self->{'Debug'};
			$self->LoadARSConfig() || do {
				$self->{'errstr'} = "ConvertFieldsToHumanReadable: can't reload config " . $self->{'errstr'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return(undef);
			};
			#if we didn't pick up the schema, barf
			exists($self->{'ARSConfig'}->{$p{'Schema'}}) || do {
				$self->{'errstr'} = "ConvertFieldsToHumanReadable: I don't know the schema: " . $p{'Schema'};
				warn($self->{'errstr'}) if $self->{'Debug'};
				return (undef);
			};
		}
	};

	#gonna be easier and faster to make a reverse hash
	my %fieldIDIndex = ();
	foreach my $field_name (keys %{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}}){
		$fieldIDIndex{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'id'}} = $field_name;
	}

	#translate field_ids to field_names
	my %translated = ();
	foreach my $field_id (keys %{$p{'Fields'}}){
		#we're either gonna know it and translate it or we're gonna throw an error
		if (exists($fieldIDIndex{$field_id})){
			$translated{$fieldIDIndex{$field_id}} = $p{'Fields'}->{$field_id};
		}else{
			$self->{'errstr'} = "ConvertFieldsToHumanReadable: I don't know the field: '" . $field_id . "' in the schema '" . $p{'Schema'} . "'";
			warn($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#translate date, datetime & time_of_day -> string
	if ($self->{'DateTranslate'} > 0){
		foreach my $field_name (keys %translated){

			if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'dataType'} eq "time"){

			    ## 1.17 - if datetime is null, no conversion necessary
			    if ($translated{$field_name} =~/^\s*$/){ next; }

				#apply the GMT offset should we have one
				if ($p{'DateConversionTimeZone'} !~/^\s*$/){
					if ($p{'plusminus'} eq "+"){
						$translated{$field_name} += ($p{'offset'} * 60 * 60);
					}elsif ($p{'plusminus'} eq "-"){
						$translated{$field_name} -= ($p{'offset'} * 60 * 60);
					}
				}

				#datetime conversion
				my $gmt_str = gmtime($translated{$field_name}) || do {
					$self->{'errstr'} = "ConvertFieldsToHumanReadable: can't convert epoch integer (" . $translated{$field_name} . ") to GMT time string: " . $!;
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};
				$translated{$field_name} = $gmt_str . " GMT";
				if ($p{'DateConversionTimeZone'} !~/^\s*$/){
					$p{'offset'} = sprintf("%02d", $p{'offset'});
					$translated{$field_name} .= " " . $p{'plusminus'} . $p{'offset'} . "00";
				}

			}elsif($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'dataType'} eq "date"){

			    ## 1.17 - if date is null, no conversion necessary
			    if ($translated{$field_name} =~/^\s*$/){ next; }

				#date ... so convoluted
				#get us back on this side of the first christmas :-/
				$translated{$field_name} -= 2440588;
				my @tmp = gmtime($translated{$field_name} * 86400);
				my $month = $month_converter[$tmp[4]];
				my $year = $tmp[5] + 1900;
				my $weekday = $weekday_converter[$tmp[6]];
				$translated{$field_name} = $weekday . ", " . $month . " " . $tmp[3] . " " . $year;

			}elsif($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'dataType'} eq "time_of_day"){

			    ## 1.17 - if time_of_day is null, no conversion necessary
			    if ($translated{$field_name} =~/^\s*$/){ next; }

				#time_of_day
				my $tmp = parseInterval(seconds => $translated{$field_name}) || do {
					$self->{'errstr'} = "ConvertFieldsToHumanReadable: can't parse time_of_day integer (" .  $translated{$field_name} . ")";
					warn($self->{'errstr'}) if $self->{'Debug'};
					return (undef);
				};

				#single zero-padding, muchacho!
				foreach ('hours', 'minutes', 'seconds'){ $tmp->{$_} = sprintf("%02d", $tmp->{$_}); }

				#ok, and I guess we'll let 'em turn off civilian time conversion if they can dig it
				if ($self->{'TwentyFourHourTimeOfDay'} != 1){
					my $ampm = "AM";
					if ($tmp->{'hours'} > 12){
						$ampm = "PM";
						$tmp->{'hours'} -= 12;
					};

					$translated{$field_name} = $tmp->{'hours'} . ":" . $tmp->{'minutes'} . ":" . $tmp->{'seconds'} . " " . $ampm;
				}else{
					$translated{$field_name} = $tmp->{'hours'} . ":" . $tmp->{'minutes'} . ":" . $tmp->{'seconds'};
				}
			}
		}
	}

	#translate enum -> string
	foreach my $field_name (keys %translated){
		if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'dataType'} eq "enum"){

			## 1.18 fix ... null enums interpret as "0" in array position (guh, thx perl)
			if ($translated{$field_name} =~/^\s*$/){
				warn ("ConvertFieldsToHumanReadable [" . $field_name . "] encountered null enum") if ($self->{'Debug'});

			}elsif ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'enum'} == 2){

				warn ("ConvertFieldsToHumanReadable [" . $field_name . "] encountered non-linear enum") if ($self->{'Debug'});

				# deal with customized non-sequential enum value lists (sheesh, BMC)
				my %inverse = ();
				foreach my $t3 (keys %{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'vals'}}){
					$inverse{$self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'vals'}->{$t3}} = $t3;
				}
				if (exists($inverse{$translated{$field_name}})){
					$translated{$field_name} = $inverse{$translated{$field_name}};
				}else{
					$self->{'errstr'} = "ConvertFieldsToHumanReadable: non-sequential custom enum list, cannot match enum value (" . $field_name . "/" . $translated{$field_name} . ")";
					warn($self->{'errstr'}) if $self->{'Debug'};
					return(undef);
				}
			}else{

				warn ("ConvertFieldsToHumanReadable [" . $field_name . "] encountered linear enum") if ($self->{'Debug'});

				# just a straight up array position, as god intended.
				if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'vals'}->[$translated{$field_name}] =~/^\s*$/){
					$self->{'errstr'} = "ConvertFieldsToHumanReadable: sequential custom enum list, cannot match enum value (" . $field_name . "/" . $translated{$field_name} . ")";
					warn($self->{'errstr'}) if $self->{'Debug'};
					return(undef);
				}else{
					$translated{$field_name} = $self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'vals'}->[$translated{$field_name}];
				}
			}
		}
	}


	#translate currency -> string
	foreach my $field_name (keys (%translated)){
		if ($self->{'ARSConfig'}->{$p{'Schema'}}->{'fields'}->{$field_name}->{'dataType'} eq "currency"){
			if (ref($translated{$field_name}) eq "HASH"){
				if (exists ($currency_codes{$translated{$field_name}->{'currencyCode'}})){
					my $prefix = ();
					foreach my $ascii (@{$currency_codes{$translated{$field_name}->{'currencyCode'}}->{'ascii_prefix_sequence'}}){
						$prefix .= chr($ascii);
					}
					$translated{$field_name} = $prefix . $translated{$field_name}->{'value'};
				}
			}
		}
	}

	#send the translated data back
	return(\%translated);
}

## DeleteObjectFromServer #######################
## for chrissakes ... be careful with this one!
## ObjectName	=> "Remedy:ARSTools:CrazyActiveLink",
## ObjectName	=> "active_link"
sub DeleteObjectFromServer {
	my ($self, %p) = @_;

	#make sure we got our required and default options, yadda yadda
	foreach ('ObjectName', 'ObjectType'){
		if ((! exists($p{$_})) || ($p{$_} =~/^\s*$/)){
			$self->{'errstr'} = "DeleteObjectFromServer: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	#here we go
	if 	($p{'ObjectType'} =~/^active_link$/i){
		#ars_DeleteActiveLink
		ARS::ars_DeleteActiveLink( $self->{'ctrl'}, $p{'ObjectName'} ) || do {
			$self->{'errstr'} = "DeleteObjectFromServer: failed to delete object from server: " . $ARS::ars_errstr;
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};
	}elsif	($p{'ObjectType'} =~/^char_menu$/i){
		#ars_DeleteCharMenu
		ARS::ars_DeleteCharMenu( $self->{'ctrl'}, $p{'ObjectName'} ) || do {
			$self->{'errstr'} = "DeleteObjectFromServer: failed to delete object from server: " . $ARS::ars_errstr;
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};
	}elsif	($p{'ObjectType'} =~/^escalation$/i){
		#ars_DeleteEscalation
		ARS::ars_DeleteEscalation( $self->{'ctrl'}, $p{'ObjectName'} ) || do {
			$self->{'errstr'} = "DeleteObjectFromServer: failed to delete object from server: " . $ARS::ars_errstr;
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};
	}elsif	($p{'ObjectType'} =~/^filter$/i){
		#ars_DeleteFilter
		ARS::ars_DeleteFilter( $self->{'ctrl'}, $p{'ObjectName'} ) || do {
			$self->{'errstr'} = "DeleteObjectFromServer: failed to delete object from server: " . $ARS::ars_errstr;
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};
	}elsif	($p{'ObjectType'} =~/^schema$/i){
		#ars_DeleteSchema
		ARS::ars_DeleteSchema( $self->{'ctrl'}, $p{'ObjectName'}, 1 ) || do {

			## NOTE: setting deleteOption to 1 (force_delete). whoo chile! be careful!

			$self->{'errstr'} = "DeleteObjectFromServer: failed to delete object from server: " . $ARS::ars_errstr;
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		};
	}else{
		$self->{'errstr'} = "DeleteObjectFromServer: I don't know how to delete the specified ObjectType: " . $p{'ObjectType'};
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	}

	return (1);

}


## ExportDefinition #############################
## export a serialized ARS Object from the ARServer in def or xml format
## on success return the serialized object, on error undef
## ObjectName	=> "Remedy:ARSTools:CrazyActiveLink",
## ObjectType	=> "active_link",
## DefinitionType	=> "xml"
## NOTE: ISS04238696 on BMC ... XML export will not work with overlays on form defs
sub ExportDefinition {
	my ($self, %p) = @_;

	#make sure we got our required and default options, yadda yadda
	foreach ('DefinitionType', 'ObjectName', 'ObjectType'){
		if ((! exists($p{$_})) || ($p{$_} =~/^\s*$/)){
			$self->{'errstr'} = "ExportDefinition: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}
	if ($p{'DefinitionType'} =~/^xml$/){
		$p{'DefinitionType'} = "xml";
		$p{'DefinitionType'} = "xml_" . $p{'ObjectType'}; ## <-- yeah that's how it works
	}elsif ($p{'DefinitionType'} =~/^def$/){
		$p{'DefinitionType'} = "def";
	}else{
		$self->{'errstr'} = "ExportDefinition: unknown 'DefinitionType' value: " . $p{'DefinitionType'};
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	}

	#"don't dude me, bro!" -- ghost adventures
	(my $def = ARS::ars_Export(
		$self->{'ctrl'},
		'',			## <-- '' = NULL = "get definition including all views" (if it's a form of course)
		'',			## <-- arsperl says '' is the same as &ARS::AR_VUI_TYPE_NONE, and I can dig it
		$p{'ObjectType'},
		$p{'ObjectName'}
	)) || do {
		$self->{'errstr'} = "ExportDefinition: failed to export definition: " . $ARS::ars_errstr;
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	};

	return($def);
}


## ImportDefinition #############################
## import a serialized ARS Object, this will be either in *.def or *.xml format
## return 1 on success. return undef on failure.
## I s'pose it goes without saying, but you know ...
## be careful, m'kay?
## options:
##	* Definition			=> $string_containing_serialized_def
##	* DefinitionType		=> "xml" | "def"
##	* ObjectName			=> $the_name_of_the_object_to_import
##	* ObjectType			=> "schema" | "filter" | "active_link" | "char_menu" | "escalation" | "dist_map" | "container" | "dist_pool"
##	* UpdateCache			=> 1 | 0 (default 0)
##	* OverwriteExistingObject	=> 1 | 0 (default 0)
sub ImportDefinition {

	my ($self, %p) = @_;

	#make sure we got our required and default options, yadda yadda
	foreach ('Definition', 'DefinitionType', 'ObjectName', 'ObjectType'){
		if ((! exists($p{$_})) || ($p{$_} =~/^\s*$/)){
			$self->{'errstr'} = "ImportDefinition: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}
	$p{'UpdateCache'} = 0 if ($p{'UpdateCache'}) != 1;
	$p{'OverwriteExistingObject'} = 0 if ($p{'OverwriteExistingObject'}) != 1;
	if ($p{'DefinitionType'} =~/^xml$/){
		$p{'DefinitionType'} = "xml";
		$p{'ObjectType'} = "xml_" . $p{'ObjectType'}; ## <-- yeah that's how it works
	}elsif ($p{'DefinitionType'} =~/^def$/){
		$p{'DefinitionType'} = "def";
	}else{
		$self->{'errstr'} = "ImportDefinition: unknown 'DefinitionType' value: " . $p{'DefinitionType'};
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return (undef);
	}

	#set up the import mode
	my $import_mode = \&ARS::AR_IMPORT_OPT_CREATE;
	if ($p{'OverwriteExistingObject'} == 1){ $import_mode = \&ARS::AR_IMPORT_OPT_OVERWRITE; }

	#like the shoe company says ...
	(my $result = ARS::ars_Import(
		$self->{'ctrl'},
		$import_mode,
		$p{'Definition'},
		$p{'ObjectType'},
		$p{'ObjectName'}
	)) || do {
		$self->{'errstr'} = "ImportDefinition: failed to import definition: " . $ARS::ars_errstr;
		warn ($self->{'errstr'}) if $self->{'Debug'};
		return(undef);
	};

	#deal with updating the cache if we gotta
	if (($p{'UpdateCache'} == 1) && (($p{'ObjectType'} eq "schema") || ($p{'ObjectType'} eq "xml_schema"))){

		#see if we got it in our schema list already
		my $found = ();
		foreach my $schema (@{$self->{'Schemas'}}){ if ($schema eq $p{'ObjectName'}){ $found = 1; last; } }
		if ($found =~/^\s*$/){ push (@{$self->{'Schemas'}}, $p{'ObjectName'}); }
		$self->{'staleConfig'} = 1;
		warn ("ImportDefinition: inserting new object into cache ...") if ($self->{'Debug'});
		$self->LoadARSConfig();

	}

	return(1);
}

## TunnelSQL ####################################
## tunnel some sql on the API
sub TunnelSQL {
	my ($self, %p) = @_;

	#make sure we got our required and default options, yadda yadda
	foreach ('SQL'){
		if ((! exists($p{$_})) || ($p{$_} =~/^\s*$/)){
			$self->{'errstr'} = "TunnelSQL: " . $_ . " is a required option";
			warn ($self->{'errstr'}) if $self->{'Debug'};
			return (undef);
		}
	}

	my $data = ARS::ars_GetListSQL(
		$self->{'ctrl'},
		$p{'SQL'}
	) || do {
		$self->{'errstr'} = "TunnelSQL: failed SQL: " . $ARS::ars_errstr;
		warn ($self->{'errstr'}) if ($self->{'Debug'});
		return (undef);
	};

	#we might not have gotten anything
	if ($data->{'numMatches'} == 0){
		$self->{'errstr'} = "no records returned";
		warn ($self->{'errstr'}) if ($self->{'Debug'});
		return(undef);
	}else{
		return($data->{'rows'});
	}
}
