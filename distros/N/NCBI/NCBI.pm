package Bio::SABio::NCBI;
use 5.006;
use warnings;
use CGI::Cookie;
use strict 'vars';
#use POSIX ceil;
use Carp;
use HTTP::Cookies;
use LWP::UserAgent;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);




@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.10';

#Nothing to export by now.
#@EXPORT = qw(...);            # symbols to export by default
#@EXPORT_OK = qw(...);         # symbols to export on request
#%EXPORT_TAGS = tag => [...];  # define names for sets of symbols

our(%parsed_features,%parsed_keys);
our($search_res);

#@create_args = qw(proxy login passwd db action formating displaymax base_url base_proj_path term);

#Those are some base spaise counter used for fasta format parsing
#actually those are number of spaises befor the information after a newline or keylike this:
#LOCUS------12 spaises------ the locus information
#or this:
#0 saices 1 acgtgtacgt agctccst
#the numbers are the number of spaices deleted automaticaly.

my %fastaorder=(
		LOCUS     => 1,
		DEFINITION => 2,
		ACCESSION  => 3,
		VERSION    => 4,
		KEYWORDS   => 5,
		SOURCE     => 6,
	        REFERENCE  => 7,
		COMMENT    => 8,
		FEATURES   => 9,          
		BASECOUNT  => 10,
		ORIGIN     => 11,
		CONTIG     => 11,
	       );

my %keyspaices=(
		LOCUS     => 12,
		DEFINITION => 12,
		ACCESSION  => 12,
		VERSION    => 12,
		KEYWORDS   => 12,
		SOURCE     => 12,
	        REFERENCE  => 12,
		COMMENT    => 12,
		FEATURES   => 21,          
		BASECOUNT  => 16,
		ORIGIN     => 6,
		CONTIG     => 24,
		);

my %valuespaices=(   
		     LOCUS     =>  2,
		     DEFINITION => 2,
		     ACCESSION  => 2,
		     VERSION    => 2,
		     KEYWORDS   => 2,
		     SOURCE     => 2,
		     REFERENCE  => 2,
		     COMMENT    => 2,
		     FEATURES   => 5,          
		     BASECOUNT  => 16,
		     ORIGIN     => 0,
		     CONTIG     => 9,
		     QUALIFIER => 16,
		     );
#BY now only some of the data is interesting ,like: why do i need all those refences?

sub new{
#maybe someday we will wont inherite it.
    my $proto = shift;  
    #print $parsed_features->{CDS}->{gene};
    my $class = ref($proto) || $proto;

    my $self = {
	base_proj_path=> '',
	base_url => 'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?',
	ncbi_url => 'http://www.ncbi.nlm.nih.gov:80',
	proxy => '',
	login => '',
	passwd => '',
	action => "Search",
	db => "nucleotide",
	request_res => '',      #the request module return data structer store it here
	request_res_text => '', #the text it self we get from the request
	ua => undef,
	formating => "Summary",
#	formating => "GenBank",
        displaymax => "1000",
        term => "Homo+sapiens+cds", 
        search_links => [],
	parsed_data => undef,
	parsed_features => undef,
	base_retrieve_url => 'http://www.ncbi.nlm.nih.gov:80',
	gb_formated_res=>'',
	feature_links => [],
	last_url => '',
	use_cookie => 1,
	cookie_file => "ncbicookies.txt",
	access_num => '',
	big_size   => 0,
	rebuilded_big => '',
	response_max_size => undef,
    }; 
    my %args;
    #the first argument could me a hash of all arguments    
    if(ref($_[1]) eq "HASH")
    {
	 my %data = $_[1];
	 foreach (keys %data)
	 {#    print $parsed_features->{CDS}->{gene};
	     $self->{$_} = $data{$_};
	 }
     }
    #the new 'operator' was called in a function manner 
    else
    {
	foreach(keys(%args))
	{
	    $self->{$_}=$args{$_};
	}
    }
    bless ($self, $class);

    $self->init_connection();
    return $self;
}

sub set{
    my ($self,%settings)=@_;
    for my $key(keys(%settings))
    {
	$self->{$key}=$settings{$key};
    }
    %parsed_keys=%{$self->{parsed_data}};
    %parsed_features=%{$self->{parsed_features}};

}

sub get{
    my ($self,%settings)=@_;
    my %requested_settings=$self;
    if(%settings)
    {
	%requested_settings=%settings;
    }
    return %requested_settings;
}

sub get_feature_links{
#the document should be already parsed for this function(i.e.call it after parse_Genbank)
#gets the feature name to be returned
    my $self=shift;
    my $needed_feature=shift;
    my %features=$self->get_parsed_features();
    my (@feature_links,$cur_link,$cur_feature);

    foreach(keys(%features))
    {
	if((split(' ',$_))[0] eq $needed_feature && ($cur_link=$features{$_}->{feature_link}))
	{

	    #sometimes there is amp; in html docs this can destorbe the request(for some reason).
	    $cur_link=~s/amp;//;

	    $cur_feature=$_;
	    push @feature_links,$_;

	    if(!/http:\/\/www\.ncbi\.nlm\.nih\.gov:80/)
	    {

		push @feature_links,$self->{ncbi_url}.$cur_link;
	    }
	    else
	    {
		push @feature_links,$cur_link;
	    }
	}
    }
    $self->{feature_links}=\@feature_links;
    return @feature_links;
}

sub init_connection{
    my $self = shift;
    $self->{ua} = LWP::UserAgent->new;
    #not sure about that
    $self->{ua}->cookie_jar(HTTP::Cookies->new(file => $self->{cookie_file},
     				       autosave => 1)) if($self->{use_cookie});
    $self->{ua}->proxy(['http', 'ftp'] => $self->{proxy}) if($self->{proxy});
}

sub verifySearch{
    my $self=shift;
    my $term=shift||$self->{term};
    my @links=@{$self->{search_links}};
    my $def=$links[3];
    my @terms=split(/\+/,$term);

    for(@terms)
    {
	my $partterm=$_;
	$partterm=~s|\[|\\\[|g;
	$partterm=~s|\\|\\\\|g;
	$partterm=~s|\/|\\\/|g;
	$partterm=~s|\.|\\\.|g;
	$partterm=~s|\*|\\\*|g;
	$partterm=~s|\#|\\\#|g;
	$partterm=~s|\&|\\\&|g;

	return 0 if(!($def=~/$partterm/i));
    }
    return 1;
}

sub verify{
    my $self=shift;
    my $term=shift||$self->{term};
    my $txt=shift||$self->{gb_formated_res};
    my @terms=split(/\+/,$term);
    for(@terms)
    {
	my $partterm=$_;
	$partterm=~s|\[|\\\[|g;
	$partterm=~s|\\|\\\\|g;
	$partterm=~s|\/|\\\/|g;
	$partterm=~s|\.|\\\.|g;
	$partterm=~s|\*|\\\*|g;
	$partterm=~s|\#|\\\#|g;
	$partterm=~s|\&|\\\&|g;

	return 0 if(!($txt=~/$partterm/i));
    }
    return 1;
}

sub search{
#the function gets the search term in
    my $self=shift;
    $self->{term}=shift;
    $self->{action}="Search";
    print "Searching : $self->{term}\n";
    return $search_res=$self->_action(); #search_res is a global /entrez/viewer.fcgi?val=20561037&from=2733485&to=2739874&strand=1var for exporting

}

sub _action{
    my $self=shift;
    my $url=$self->{base_url}."cmd=".$self->{action}."&db=".$self->{db}."&term=".
	$self->{term}."&dispmax=".$self->{displaymax}."&doptcmdl=".$self->{formating};

    return $self->_request($url);
}

sub download_seq_only{
    my $self=shift;
    my $ac_num=shift||$self->{parsed_data}->{ACCESSION};
    $self->_request("http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=".$ac_num."&txt=on&view=fasta");
}

sub _request{
    my $self=shift;
    my $url=$self->{last_url}=shift;
    my $max_size=shift||$self->{response_max_size};

    #set the maximum size of the response
    if(defined($max_size))
    {
	$self->{ua}->max_size($max_size);
    }
    my $req = HTTP::Request->new('GET',$url);
    #"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&db=nucleotide&term=Homo+sapiens");
    $req->proxy_authorization_basic($self->{login},$self->{passwd})  if ($self->{login});
    #the search_res variable should hold the result for evaluation,the global one for excess from the outside
    $self->{request_res} = $self->{ua}->request($req);
    # Check the outcome of the response

    if ($self->{request_res}->is_success) {
	$self->{request_res_text}=$self->{request_res}->content;
	return 	$self->{request_res_text};
    } else {
	carp "The request fail for $url\n";
	return $self->{request_res_text}='';
    }
    #redefine max_size
   $self->{ua}->max_size(undef) if(defined($max_size));
}

sub download_feature_link{
    my ($self,$link)=@_;
    #check for relative link
    $link="http://www.ncbi.nlm.nih.gov:80".$link     if(!($link=~/http:\/\/www\.ncbi\.nlm\.nih\.gov:80/));
    my $res=$self->_request($link);    
    $res=~s|.*(LOCUS.*\n\/\/).*|$1|s || $res=~s|.*(CONTIG.*\n\/\/).*|$1|s;    
    return $self->{gb_formated_res}=$res;    
}

sub download_region{
    my($self,$what,$from,$to)=shift;
    my $url='http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?';
    $url.="val=".$what."&from=".$from."&to=".$to;
    $self->_request($url);
}

sub download_locus{
    my ($self,$list_uids,$dopt,$name,$def)=@_;

    $dopt=$dopt||"GenBank";
    my $url = $self->{base_url}."cmd=Retrieve"."&db=".$self->{db}."&list_uids=".$list_uids."&dopt=".$dopt;
#    print $url; 
    #Download the "HEADER" of the file
    my $res=$self->_request($url,7000);
    print $res;
    $res=~s/(LOCUS.*?\n)/$1/;
    return $1;
}

sub check_download_size{
    my ($self,$list_uids,$dopt,$name,$def)=@_;
    my $bp;
    if($bp=$self->download_locus($list_uids,$dopt,$name,$def))
    {
	$bp=~/(\d+)\sbp/;
	$bp=$1;
	$self->{big_size}=$bp;
	#file is too big
	if($self->{response_max_size} < $bp)
	{
	    return $bp;
	}
	#file is all right
	else
	{
	    return -1;
	}
    }
    #couldn't get the locus line
    else
    {
	return 0;
    }
}

sub rebuild_big{
    my $self=shift;
#    if(!$self->{rebuilded_big});
}

#not finished
sub download_big{
    my ($self,$list_uids,$size)=@_;
    my $requestsnum=int($size/$self->{response_max_size}+0.5);

    for(my $i=1;$i<=$requestsnum;$i++)
    {
	my $packetsize=$i*$self->{response_max_size};
	if($packetsize<=$size)
	{
	    $self->download_region($list_uids,($i-1)*$self->{response_max_size},$packetsize);	
	}
	else
	{
	    $self->download_region($list_uids,($i-1)*$self->{response_max_size},$size);			
	}
	
    }

}


sub download_big_search{
    my ($self,$list_uids,$dopt,$name,$def)=@_;    
    my $size=check_download_size($list_uids,$dopt,$name,$def);
    my $packetsize;
    if(!$size)
    {
	return download_search_link($list_uids,$dopt,$name,$def);
    }
    elsif(0 < check_download_size($list_uids,$dopt,$name,$def))
    {
	#connection problem
	return $self->{gb_formated_res}='';
    }
    else
    {
	$self->download_big();
    }
}
sub parse_search_res{
#the function can parse text from the class or from string it get in @_.
    my @search_res=();
    my $self=shift;
    my $txt = shift||$self->{request_res_text};   
    my @w = ($txt =~ m|list_uids=(\d*).*?dopt=(.*?)\"\>(.*?)\<|g);
    my @definitions=($txt =~ m|\<dd\>(.*?)\<br\>|g);
    for(@definitions)
    {
	for(my $i=0;$i<3;$i++)
	{
	    push(@search_res,(shift @w));
	}
	push(@search_res,(shift @definitions));
    }
    return $self->{search_links}=\@search_res;

}

=head1
here is the data structure for parsed file:
%data{
 $key => key_text,
 #the keys are specified in spaices hash (the numbers are the number of blank lines befor the text it self)
}
=cut

=head1
here is the data structure for parsed features:
    %parsed_features=(
                    $feature_key=>(
                                  'feature_link'=>link,
                                  $qualifier=>(
	                                      'value'         =>value or [value1,value2,...,valueN],
	                                      'qualifier_link'=>link or [link1,link2,...,linkN],
				               )
                                   )
                      )
#if there is more then one same qualifier ,then values are concatu. into one value string ,with delimeter $$$.
=cut

sub parse_GenBank{
    my $self=shift;
    my $key;
    my $push=0;
    my $txt=shift||$self->{gb_formated_res};
    undef %parsed_keys;
    undef %parsed_features;
       

    my @row_genbank_lines=split(/^/,$txt);
    #pop out the // at the end of file
    pop @row_genbank_lines;

    foreach(@row_genbank_lines)
    {
	#new key found
	if(/^([A-Z]+\s[A-Z]+)/ || /^([A-Z]+)\&?/)
	{

	    if($keyspaices{$1})
	    {
		$key=$1;
		#also delete extra spaices at the begining of the line
		$push=1 ;
		$parsed_keys{$key}=substr($_,$keyspaices{$1});

	    }
	    else 
	    {
		$push=0;
	    }
	}
	else
	{
	    $parsed_keys{$key}.=substr($_,$valuespaices{$key})  if($push );#&& substr($_,0,12) ne ' 'x12); 
	}
    }
    #parse features
    my $tmp='';
    my $feature_key='';
    my $qualifier=0;
    my @t=split(/^/,$parsed_keys{FEATURES});
#    print $parsed_keys{FEATURES};
    shift @t;   #The first line is Location/Qualifiers
    for(my $i=0;$i<=$#t;$i++)
    {

	$tmp=$t[$i];
	if($tmp=~/^\S/) #new feature found
	{
	    #extract links
	    $feature_key=$tmp;
	    $feature_key=~s/<a href=(.*?)>(.*?)<\/a>/$2/;
	    my $link=$1;

	    #delete extra spaices at the begining & in the middele
	    $feature_key=~s/\s+/ /g;

	    #chomp extra spaices at the end
	    $feature_key=~s/\s+$//g;

	    #reformat html characters
	    $feature_key=~s/&lt;/</g;
	    $feature_key=~s/&gt;/>/g;

	    #sometimes feature case while reading by perl wrops to 2 lines ,for example: gene
	                                                                               # 1..4696
	    #then get both lines for index.
	    chomp $feature_key ;
	    while(!($t[$i+1]=~/^\s*\/(.*)/)) 
	    {
		$i++;
		my $tmp=substr($t[$i],$valuespaices{QUALIFIER});
		#chomp the \n on the end using precasions
		my $sep=$/;
		$/="\n";
		chomp $tmp;
		$/=$sep;
		#chomp extra spaices at the end
		$tmp=~s/^\s+//;
		$feature_key.=$tmp;
	    }
	    $parsed_features{$feature_key}->{feature_link}=$link;
	}
	else
	{
	    my $feature=substr($tmp,$valuespaices{QUALIFIER});
	    if($feature=~/^\/(.*?)=(.*)/) #new qualifier found
	    {
		$qualifier=$1;
		my $value=$2;
		if($value=~s/<a href=(.*?)>(.*?)<\/a>/$2/)
		{
		    $parsed_features{$feature_key}->{$qualifier}->{qualifier_link}=$1 ;
		}

		push (@{$parsed_features{$feature_key}->{$qualifier}->{value}},$value."\n");
	    }
	    else
	    {
		my $last=$#{@{$parsed_features{$feature_key}->{$qualifier}->{value}}};
		${$parsed_features{$feature_key}->{$qualifier}->{value}}[$last].=$tmp;
	    }
	}
    }

    $self->{parsed_data}=\%parsed_keys;
    $self->{parsed_features}=\%parsed_features;
}

sub reconstructFasta{
    my $self=shift;
    my %parsed_keys=shift||%{$self->{parsed_data}};
    my $txt='';
    for my $key(sort {$fastaorder{$a} <=> $fastaorder{$b}} keys(%parsed_keys))
    {
	my $spaices=$keyspaices{$key}-length($key);
	my @values=split(/^/,$parsed_keys{$key});
	$txt.=$key." "x$spaices.(shift(@values));
	for my $value(@values)
	{
	    $txt.=" "x$valuespaices{$key}.$value;
	}
    }
    $txt.='//';
    return $txt;
}

=head1
here is the data structure for parsed features:
    %parsed_features=(
                     $feature_key=>(
                                  'feature_link'=>link,
                                  $qualifier=>(
	                                      'value'         =>value or [value1,value2,...,valueN],
	                                      'qualifier_link'=>link or [link1,link2,...,linkN],
				               )
                                   )
                      )
#if there is more then one same qualifier ,then values are concatu. into one value string ,with delimeter $$$.
=cut

sub reconstructQaulifier{
    my $self=shift;
    my $feature_key=shift;
    my $requered_link=shift||0;
    my %feature=%{$self->{parsed_features}->{$feature_key}};
    my @fkey=split(' ',$feature_key);
    my $txt=$fkey[0]." "x($valuespaices{QUALIFIER}-length($fkey[0])).$fkey[1]."\n";
    foreach my $qualifier(keys(%feature))
    {
	for(@{$feature{$qualifier}{'value'}})
	{
	    $txt.=" "x$valuespaices{QUALIFIER}.'/'.$qualifier.'='.$_;
	}
    }
    return $txt;
}

sub reconstructFeatures{
    my $self=shift;
    my $links_requered=shift||0;
    my %parsed_features=shift||%{$self->{parsed_features}};
#     $parsed_features{"pushed 126"}="134";
    my $txt='Location/Qualifiers'."\n";
    my $func=sub{
	           if($_[0]=~/source/ && $_[1]=~/source/)
		   {
		       return (($_[0]=~/.*?(\d+)/)[0] <=> ($_[1]=~/.*?(\d+)/)[0]);		       
		   }
	           return -1 if($_[0]=~/source/); 
		   return (($_[0]=~/.*?(\d+)/)[0] <=> ($_[1]=~/.*?(\d+)/)[0]);
		   };
    for my $key(sort {&$func($a,$b)} keys(%parsed_features))
    {
	$txt.=$self->reconstructQaulifier($key);
    }
    $parsed_keys{FEATURES}=$txt;
    return $txt;
}

sub get_feature{
    my $self=shift;
    my $needed_feature=shift;
    my %features=$self->get_parsed_features();
    my (%needed_feature);

    foreach(keys(%features))
    {
	if((split(' ',$_))[0] eq $needed_feature )
	{
	    $needed_feature{$_}=$features{$_};
	}
    }

    return %needed_feature;
}

sub get_parsed_keys{
    my $self=shift;
    return %{$self->{parsed_data}};
}

sub get_accession{
    my $self=shift;
    return $self->{parsed_data}->{ACCESSION};
}

sub get_gi{
    my $self=shift;
    my $version=$self->{parsed_data}->{VERSION};
    $version=~/(GI:\S+)/;
    my $gi=$1;
    return $gi;

}

sub get_parsed_features{
    my $self=shift;
    return %parsed_features;
}

=head1
    my ($self,$list_uids,$dopt,$name,$def);
    this array includes:
    $self - the class;
    $list_uids - the ids of the document to download;
    $dopt - data base of the document(you can't use here $self->{db} that will exclude all search results from athor dbs;
    $name - the "name" (accession number ) of the document;
    $def - the definiton of the document;
It is anof to specify $list_uids and $dopt for downloading ,thought;
=cut
sub download_search_link{
    my ($self,$list_uids,$dopt,$name,$def)=@_;
    $dopt=$dopt||"GenBank";
    $self->{formating}="GenBank"||$self->{formating};
    my $url = $self->{base_url}."cmd=Retrieve"."&db=".$self->{db}."&list_uids=".$list_uids.
    #althought in the documentation using "list_uids" is propagated the uid seems working better
	"&dopt=".$dopt;
    print "Downloading $name;\n";   
    my $res=$self->_request($url);
    $res=~s|.*(LOCUS.*\n\/\/).*|$1|s || $res=~s|.*(CONTIG.*\n\/\/).*|$1|s;
    return $self->{gb_formated_res}=$res;
}

sub download_next_search_link{
    my $self=shift;
    return -1    if($#{@{$self->{search_links}}}<=0);

    my $list_uids=shift @{$self->{search_links}};
    my $dopt=shift @{$self->{search_links}};
    my $name=shift @{$self->{search_links}};
    my $def=shift @{$self->{search_links}};

    return $self->download_search_link($list_uids,$dopt,$name,$def);
}

sub download_search_all{
    my $self=shift;
    #download links from @_ if there is such or from links stored in the class already.
    my $txt=shift||$self->{request_res_text};
    $self->parse_search_res($txt);
    my @w = @{$self->{search_links}};
    
    for(my $i=0;$i<=($#w)/3;$i+=4)
    {
	$self->download_search_link($w[$i],$w[$i+1],$w[$i+2],$w[$i+3]);
	if($self->{request_res}->is_success)
	{
	    open(FILE,">$self->{base_proj_path}$w[$i+2].htm");
	    print FILE $self->{request_res_text};
	    close FILE;
	}
    }	#$intron_counter++;
}

sub redo{
    my $self=shift;
    return $self->_request($self->{last_url});
}

sub request4gb{
    my $self=shift;
    my $txt=shift||$self->{request_res_text};
    $txt=~s/<input name=\"query_key\" type=\"hidden\" value=\"(\d*)\">/$1/s;
    my $qk=$1;
    my $url="http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?cmd=&txt=&save=0&cfm=&query_key=".$qk."&db=nucleotide&view=gb";
    my $res=$self->_request($url);
    $res=~s|.*(LOCUS.*\n\/\/).*|$1|s || $res=~s|.*(CONTIG.*\n\/\/).*|$1|s;
    return $self->{gb_formated_res}=$res;

}

sub is_gb{
    my $self=shift;
    my $txt=shift||$self->{request_res_text};
    return $txt=~/.*(LOCUS.*\n\/\/).*/s || $txt=~/.*(CONTIG.*\n\/\/).*/s;
}

sub text{
    my $self=shift;
    my $uid=shift;
    my $url=$self->{base_url}."cmd=".$self->{action}."&db=".$self->{db}."&uid=".
	$self->{term}."&dispmax=".$self->{displaymax}."&dopt=".$self->{formating};

    return $self->_request($url);
}

1;
__END__
=head1 NAME

Bio::SABio::NCBI - Downloads and parse DNA data from NCBI site

=head1 SYNOPSIS

  use Bio::SABio::NCBI;

=head1 DESCRIPTION

This module works also under Win32 ,it does not require
any ather packeges,is much simplier for use and instalation.(after
it will be released) .It will *not* force user to learn complicated
object relations and behavior ,as the bioperl project,in case he
wants to do as simple things as- getting DNA data from the
web,parsing it ,searching desirable chunk and (maybe in future)
running standart biological algoritms on it.
It will be able to download realy big files from NCBI ,such as contigs - 
not causing server error on the site.
The module also can be use with proxes.


=head2 EXPORT

None by default.


=head1 AUTHOR

Tsirkin Evgeny, E<lt>tsurkin@mail.jct.ac.ilE<gt>

=head1 SEE ALSO

L<perl>.

=cut
