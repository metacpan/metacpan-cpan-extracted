use Template::Plex;

my $vars={
	size=>"large",
	slices=>8,
	people=>[qw<Kim Sam Harry Sally>]
};

my $template= Template::Plex->load(\*DATA, $vars);

print $template->render;	

$vars->{size}="extra large";
$vars->{slices}=12;

print $template->render;


#Write a template:
__DATA__
@{[ 
    init {
	use Time::HiRes qw<time>;
  a+1
	$title="Mr.";
    }
]}

Dear $title Connery,
Ordered a $size pizza with $slices slices to share between @$people and
myself.  That averages @{[$slices/(@$people+1)]} slices each.
