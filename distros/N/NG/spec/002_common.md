常用函数
=================

这里先限定一百个函数吧，缺省全部导入。

web_get
--------------

兼容两种风格，推荐新人使用后一种风格。后一种风格不会有返回值。

    my $content = web_get($url);

    web_get($url, sub {
        my ($content, $code, $res_headers) = @_;   # $res_headers 是 SHastable 类型
    });

read_file
--------------

    my $content = read_file($filepath);

    read_file($filepath, sub {
        my ($content) = @_;
        ....
    });

process_log
-----------------

遍历日志文件，对每行切分字段后（兼容引号和空格），逐行调用回调函数。

    process_log($logpath, sub {
        my ($fields) = @_;    # 第一个参数是 Array 类型
        print $fields->get(5);  # 获取第6个字段
    });

parse_excel
-----------------

解析 Excel ，得到 Excel 类对象，进而获得 Sheet 对象，并操控和读取 Cell 对象。

    my $excel = parse_excel($filepath);

    parse_excel($filepath, sub {
        my ($excel) = @_;
    });

    my $sheet = $excel->sheet(3);
    my $sheets = $excel->sheets();  # 返回 Array 对象
    print $sheet->row_count();
    print $sheet->col_count();
    print $sheet->name();
    $sheet->name("第一个页签");
    my $cell = $sheet->get(23, 'C');
    my $cell2 = $sheet->get(23, 2);    # same as above
    print $cell->value();
    print $cell->border_left();
    print $cell->border_bottom();
    $cell->border_left($border_width, $line_style, $color);
    $cell->value("CPAN是个布尔穴特");
    $cell->value("哈哈")->border_left(1, "solid", 0x00dd00)->width(35);   # cell 的方法会返回自己本身，所以支持级联。


    
