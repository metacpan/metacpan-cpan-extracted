// combine back str group to string
function combine_str_group(group, is_hash_style) {
    var records = [];
    for (var r in group.records) {
        r = group.records[r];
        
        if (is_hash_style) {
            records.push(
                "    " + r.left +
                          ' '.repeat(group.indent - r.left.length - 3) +
                          "=> " + r.right
            );
        }
        else {
            records.push(
                '    ' + r.left +
                         ' '.repeat(group.indent - r.left.length) +
                         r.right
            );
        }
    }
    
    if (!is_hash_style && group.affected) records.sort();
    
    return records.join('\n');
}

// inject new not found pattern in the right place
function inject_new_notfound_pattern(pat, server, group) {
    // check indent width: '' + spaces + =>
    if (server.length + 6 > group.indent) {
        group.indent = server.length + 6;
    }
    group.records.push({
        left: "'" + server + "'",
        right: "'" + pat + "',"
    })
}

//  check is server name a equals server name b, at least partly
function server_names_cmp(a, b) {
    // server.whois.ru.com -> ['server', 'whois.ru.com']
    var parts_a = a.split('.');
    var len = parts_a.length - 1;
    var tld_finish = len - 1;
    for (; tld_finish > 0; tld_finish--) {
        if (parts_a[tld_finish] == 'nic' || parts_a[tld_finish].length > 3)
            break;
    }
    parts_a[tld_finish] += '.' + parts_a.splice(tld_finish+1).join('.');
    
    // same for b
    var parts_b = b.split('.');
    len = parts_b.length - 1;
    tld_finish = len - 1;
    for (; tld_finish > 0; tld_finish--) {
        if (parts_b[tld_finish] == 'nic' || parts_b[tld_finish].length > 3)
            break;
    }
    parts_b[tld_finish] += '.' + parts_b.splice(tld_finish+1).join('.');
    
    // now cmp from the end
    var len_a = parts_a.length;
    var len_b = parts_b.length;
    var i, j = 1;
    for (i=len_a-1; i>=0 && j<=len_b; i--, j++) {
        if (parts_a[i] != parts_b[len_b-j]) break;
    }
    
    // return rating
    return (len_a-i-1)/len_a * (j-1)/len_b;
}

// inject new tld server in the right place
function inject_new_whois_server(tld, server, groups) {
    var rating = {};
    
    for (var i=0; i<groups.length; i++) {
        rating[i] = 0;
        for (var r in groups[i].records) {
            rating[i] += server_names_cmp(groups[i].records[r].right, server);
        }
    }
    
    var srk = Object.keys(rating).sort(function(a, b) { return rating[b] - rating[a]; });
    if (rating[ srk[0] ] == 0) {
        // no appropriate group found, create new one
        
        // try to get indent from last group to look cool
        var indent = groups[groups.length-1].indent;
        if (tld.length + 2 > indent) {
            indent = tld.length + 2;
        }
        
        groups.push({
            indent: indent,
            affected: false,
            records: [{
                left: tld,
                right: server
            }]
        });
    }
    else {
        // group found
        var group = groups[ srk[0] ];
        if (tld.length + 2 > group.indent) {
            group.indent = tld.length + 2;
        }
        group.affected = true;
        
        group.records.push({
            left: tld,
            right: server
        });
    }
}

// split str group to left and right parts
// with indent width info saved
function parse_str_group(str) {
    str = $.trim(str);
    var lines = str.split('\n');
    var result = {
        indent: null,
        affected: false,
        records: []
    };
    
    for (var line in lines) {
        line = $.trim(lines[line]);
        if (!result.indent) {
            var parts = adequate_split(line, /\s+/, 3);
            result.indent = line.length - parts[parts.length-1].length;
        }
        
        var parts = adequate_split(line, /\s+/, 3);
        result.records.push({
            left: parts[0],
            right: parts[parts.length-1] // =>
        });
    }
    
    return result;
}

// "sds dsfds dfd dfd".split(/\s+/, 3) -> ['sds', 'dsfds', 'dfd']
// JavaScript are u kidding me?
function adequate_split(str, pat, limit) {
    var res = [];
    var i;
    for (i = 0; i < limit-1; i++) {
        var match;
        if (match = str.match(pat)) {
            res.push(str.substring(0, match.index));
            str = str.substring(match.index+match[0].length);
        }
        else {
            res.push(str);
            break;
        }
    }
    if (i == limit-1) res.push(str);
    
    return res;
}
