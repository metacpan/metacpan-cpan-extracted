$(function() {
    $('#process').click(function() {
        var new_tlds = [];
        var not_selected = 0;
        var server_empty = 0;
        var first = true;
        
        // push all input into array
        $('#result tr').each(function() {
            if (first) {
                first = false;
                return;
            }
            
            var self = $(this);
            var tld = self.find('td[data-id="tld"]').text();
            var td_whois = self.find('td[data-id="whois_server"]');
            var whois_server = td_whois.find('input[type="text"]').val();
            var selected = td_whois.find('input[type="radio"]:checked').val();
            var notfound_pat = self.find('td[data-id="notfound"] input[data-id="notfound_pat"]').val();
            
            new_tlds.push({
               tld: tld,
               whois_server: whois_server,
               notfound_pat: notfound_pat,
               selected: selected 
            });
            
            if (!selected) not_selected++;
            if (!whois_server) server_empty++;
        })
        
        // check for user errors
        if (server_empty || not_selected) {
            if ( !confirm((server_empty ? server_empty + ' whois servers empty, ' : '') +
                          (not_selected ? not_selected + ' items not processed, ' : '') +
                          'are u sure u want to continue? All of this tlds will be skipped') ) {
                return;
            }
        }
        
        this.disabled = true;
        
        // get servers from perl sourcecode
        var source = $('#source').val();
        var match = source.match(/our\s+%servers\s*=\s*qw\(((?:.|\n)+?)\);/);
        if (!match) {
            alert('Unexpected fail: can not find %servers in Data.pm');
            return;
        }
        
        var raw_servers = match[1];
        var raw_servers_groups = raw_servers.split(/\n[ \t]*\n/);
        var servers_groups = [];
        for (var rsg in raw_servers_groups) {
            servers_groups.push( parse_str_group( raw_servers_groups[rsg] ) );
        }
        
        // get not found patterns from perl sourcecode
        match = source.match(/our\s+%notfound\s*=\s*\(\n((?:.|\n)+?)\);/);
        if (!match) {
            alert('Unexpected fail: can not find %notfound in Data.pm');
            return;
        }
        
        var raw_notfound = match[1];
        var raw_notfound_groups = raw_notfound.split(/\n[ \t]*\n/);
        // always push to last nf group
        var notfound_group = parse_str_group( raw_notfound_groups[raw_notfound_groups.length - 1] );
        
        // process
        for (var tld_r in new_tlds) {
            tld_r = new_tlds[tld_r];
            
            if (tld_r.selected != 'accept' || !tld_r.whois_server) {
                continue;
            }
            
            // whois server
            inject_new_whois_server(tld_r.tld, tld_r.whois_server, servers_groups);
            // not found pattern
            if (tld_r.notfound_pat)
                inject_new_notfound_pattern(tld_r.notfound_pat, tld_r.whois_server, notfound_group);
        }
        
        // combine back to string
        for (var i in servers_groups) {
            raw_servers_groups[i] = combine_str_group( servers_groups[i] );
        }
        raw_servers = raw_servers_groups.join('\n\n');
        
        raw_notfound_groups[raw_notfound_groups.length - 1] = combine_str_group( notfound_group, true );
        raw_notfound = raw_notfound_groups.join('\n\n');
        
        // replace in source code
        source = source.replace(/our\s+%servers\s*=\s*qw\(\s*(?:.|\n)+?\);/, 'our %servers = qw(\n' + raw_servers + '\n);');
        source = source.replace(/our\s+%notfound\s*=\s*\(\s*(?:.|\n)+?\);/, 'our %notfound = (\n' + raw_notfound + '\n);');
        $('#source').val(source);
        
        $('#source_block').show();
        $('html, body').animate({
            scrollTop: $("#source_block").offset().top
        }, 2000);
    })
})
