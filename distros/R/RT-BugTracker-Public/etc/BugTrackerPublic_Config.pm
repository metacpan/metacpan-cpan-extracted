# Read more about options in lib/RT/BugTracker/Public.pm

Set($WebPublicUser, 'public') unless RT->Config->Meta('WebPublicUser');
Set($WebPublicUserReporting, 0) unless RT->Config->Meta('WebPublicUserReporting');
Set($WebPublicUserSortResults, 0) unless RT->Config->Meta('WebPublicUserSortResults');
Set($ScrubInlineArticleContent, 1) unless RT->Config->Meta('ScrubInlineArticleContent');

