var OpusVL_tablesorter_parser = function() {
    var date_pattern = /^\s*(\d+)-([a-z]+)-(\d+)(\s+(\d+:\d+))?\s*$/i;
    var month_map = {
        'jan' : '01',
        'feb' : '02',
        'mar' : '03',
        'apr' : '04',
        'may' : '05',
        'jun' : '06',
        'jul' : '07',
        'aug' : '08',
        'sep' : '09',
        'oct' : '10',
        'nov' : '11',
        'dec' : '12',
    };
    return { 
        id: 'opus-dates', 
        is: function(s) { 
            if(s) {
                return s.match(date_pattern);
            }
            return false; 
        }, 
        format: function(s) { 
            if(s) {
                var result = s.match(date_pattern);
                if(result) {
                    return result[3] + '-' + month_map[result[2].toLowerCase()] + '-' + result[1] + (result[4] || '');
                }
            }
            return s;
        }, 
        type: 'text' 
    }
};
$.tablesorter.addParser(OpusVL_tablesorter_parser()); 

