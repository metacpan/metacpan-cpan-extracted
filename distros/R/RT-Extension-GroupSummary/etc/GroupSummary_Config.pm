# This controls the display of lists of groups returned from the Group
# Summary Search.

Set($GroupSearchResultFormat,
         q{'<a href="__WebPath__/Group/Summary.html?id=__id__">__id__</a>/TITLE:#'}
        .q{,'<a href="__WebPath__/Group/Summary.html?id=__id__">__Name__</a>/TITLE:Name'}
        .q{,'__Description__/TITLE:Description'}
);
