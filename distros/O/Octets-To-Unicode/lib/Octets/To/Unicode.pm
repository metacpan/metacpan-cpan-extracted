package Octets::To::Unicode;
use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

our $VERSION = "0.06";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  grep { *{ $Octets::To::Unicode::{$_} }{CODE} } keys %Octets::To::Unicode::;

use Encode qw//;

#=========================================
#@category Кодировка

# Определяет кодировку.
sub bohemy($) {
    my ($s) = @_;
    my $c = 0;
    while ( $s =~ m![а-яё]+!gi ) {
        my $len = length $&;
        if    ( $& =~ /^[А-ЯЁ][а-яё]+$/ ) { $c += $len }
        elsif ( $& =~ /^[А-ЯЁ]+$/ )       { $c += $len / 3 }
        elsif ( $& =~ /^[а-яё]+$/ )       { $c += $len / 3 }
        else                              { $c -= $len }
    }
    $c;
}

# Определить кодировку и декодировать
sub decode(@) {
    my ( $octets, $encodings ) = @_;

    return if !length $octets;

    utf8::encode($octets) if utf8::is_utf8($octets);

    $encodings //= [qw/utf-8 cp1251 koi8-r/];

    my @x = grep length $_->[0], map {

# В случае ошибки Encode::decode помещает пустую строку в свой второй аргумент. Какой-то баг.
        my $save = $octets;
        eval { [ Encode::decode( $_, $save, Encode::FB_CROAK ), $_ ] };
    } @$encodings;

    my ( $unicode, $mem_encoding );
    ( $unicode, $mem_encoding ) = @{ $x[0] } if @x == 1;

    if ( @x > 1 ) {
        ( $unicode, $mem_encoding ) =
          @{ ( sort { bohemy( $b->[0] ) <=> bohemy( $a->[0] ) } @x )[0] };
    }

    wantarray ? ( $unicode, $mem_encoding ) : $unicode;
}

# Определить кодировку
sub detect(@) {
    ( decode @_ )[1];
}

#=========================================
#@category Вспомогательные функции

# Ищет файлы в директориях рекурсивно
sub file_find($);

sub file_find($) {
    my ($file) = @_;
    if ( -d $file ) {
        $file =~ s!/$!!;
        map file_find($_), <$file/*>;
    }
    else {
        $file;
    }
}

# Чтение бинарного файла
sub file_read($) {
    my ($file) = @_;
    open my $f, "<", $file
      or die "При открытии для чтения $file произошла ошибка: $!.";
    read $f, my $buf, -s $f;
    close $f;
    $buf;
}

# Запись в бинарный файл
sub file_write(@) {
    my ( $file, $unicode ) = @_;

    utf8::encode($unicode) if utf8::is_utf8($unicode);

    open my $f, ">", $file
      or die "При открытии для записи $file произошла ошибка: $!.";
    print $f $unicode;
    close $f;
    return;
}

# Определить кодировку и декодировать файл
sub file_decode(@) {
    my ( $file, $encodings ) = @_;
    decode file_read $file, $encodings;
}

# Кодировать в указанной кодировке и записать в файл
sub file_encode(@) {
    my ( $file, $encoding, $unicode ) = @_;

    utf8::decode($unicode) if !utf8::is_utf8($unicode);

    $unicode = Encode::encode( $encoding, $unicode ) if defined $encoding;

    file_write $file, $unicode;
}

#=========================================
#@category Тестирование файлов

# Если расширение отсутствует, то 1-я строка должна содержать #!(.*)$interpreter
# * $exts — расширения: [qw/pl pm py/]
# * $interpreters — интерпретаторы: [qw/perl python/]
# Примечание: $interpreters проверяются только для файлов без расширений и только если пустое расширение было в $exts
sub test_file(@) {
    my ( $file, $exts, $interpreters ) = @_;

    $exts         //= [];
    $interpreters //= [];

    my ($ext) = $file =~ /\.([^.\/]*)$/;

    return @$exts ? ( 1 == grep { $ext eq $_ } @$exts ) : 1 if defined $ext;

    open my $f, "<", $file or die "$file: $!";
    read $f, my $buf, 2;
    close($f), return 0 if $buf ne "#!";

    return 1 if !@$interpreters;

    my $first_line = <$f>;
    close $f;

    $interpreters = join "|", @$interpreters;

    $first_line =~ /.*\b($interpreters)\b/ ? 1 : 0;
}

# Тестирует файлы на соответствия расширениям
sub test_files(@) {
    my ( $files, $exts, $interpreters ) = @_;

    $exts         = [ split /,/, $exts ]         if !ref $exts;
    $interpreters = [ split /,/, $interpreters ] if !ref $interpreters;

    grep test_file( $_, $exts, $interpreters ), @$files;
}

# Возвращает изменённые файлы в репозитории git
sub change_files() {
    map { file_find $_ }
      map { s/^\s*[\w\?]+\s+//; $_ } grep { !/^\s*D / } split /\n/,
      `git status -s`;
}

# Возвращает изменённые файлы в ветке
sub change_files_in_branch() {
    grep length, split "\n",
      `git diff --name-only --diff-filter=AM origin/master...`;
}

1;
__END__

=encoding utf-8

=head1 NAME

Octets::To::Unicode - модуль и утилиты ru-perltidy и ru-utf8 для распознавания кодировки текста (в том числе в файлах) и его декодирования.

=head1 VERSION

0.01

=head1 SYNOPSIS

	use Octets::To::Unicode;
	
	my $unicode = decode "Стар Трек";
	my ($unicode, $encoding) = decode "Стар Трек";
	my $unicode = decode $octets_in_cp1251_or_maybe_in_utf8, [qw/cp1251 utf-8/];
	
	my $encoding = detect $octets;
	my $encoding = detect $octets, [qw/cp1251 utf-8/];
	
	my ($file_text_in_unicode, $encoding) = file_decode "path/to/file", ["cp1251", "koi8-r"];
	file_encode "path/to/file2", "koi8-r", $file_text_in_unicode;

Использование утилит:

	# Отформатировать указанные файлы perltidy:
	$ ru-perltidy file1 file2

	# Указать кодировку:
	$ ru-perltidy file1 file2 -e utf-8,cp1251

	# Форматирует только изменённые файлы в репозитории git:
	$ ru-perltidy

	# Форматирует изменённые файлы в ветке (на случай, если забыл отформатировать перед комитом):
	$ ru-perltidy --in-branch

	# Указать расширения файлов:
	$ ru-perltidy --ext 'pl,pm,'
	
	# Обработать файлы в директориях:
	$ ru-perltidy --in-dir .,/tmp/mydir

	# Выполнить операцию с файлами:
	$ ru-utf8 file1 file2 -c 'perltidy $f -st > $o'
	
	# Переменные, которые можно использовать:
	$ ru-utf8 file1 file2 -c 'echo $f $o $e $x'
	$ ru-utf8 file1 file2 -o -c 'echo $f1 $o1 $e1 $x1 - $f2 $o2 $e2 $x2'
	
	# Кроме команды шелла можно использовать ещё код perl:
	$ ru-utf8 file1 file2 -s 'print "$f $o $e $x -- $unicode\n"'
	$ ru-utf8 file1 file2 -o -s 'print "@f @o @e @x"'
	
	# Определить кодировку файлов и перекодировать их в koi8-r:
	$ ru-encode -t koi8-r

=head1 DESCRIPTION

Пакет включает в себя утилиты:

=over 4

=item B<ru-perltidy> — форматирует файлы через perltidy c определением их кодировки;

=item B<ru-utf8> — переводит файлы во временные (в кодировке utf-8), выполняет указанную команду и переписывает обратно в определённой кодировке;

=item B<ru-encode> — перекодирует файлы в указанную кодировку.

=back

и модуль perl:

=over 4

=item B<Octets::To::Unicode> — модуль c функциями определения кодировки текста и его конвертирования между кодировками.

=back

B<Octets::To::Unicode> предоставляет необходимое множество утилит для определения кодировки текста и его декодирования, а так же — работы с файлами.

В 2000-х определилась тенденция переводить проекты в национальных кодировках в utf-8. Однако не везде их перевели одним махом, а решили рубить собаке хвост постепенно. В результате во многих проектах часть файлов c кодом в utf-8, а часть — в национальной кодировке (cp1251, например).

Ещё одной проблемой могут служить урлы с эскейп-последоваительностями. Например, https://ru.wikipedia.org/wiki/Молчание#Золото преобразуется в мессенджере, куда эту ссылку можно скопировать, в https://ru.wikipedia.org/wiki/%D0%9C%D0%BE%D0%BB%D1%87%D0%B0%D0%BD%D0%B8%D0%B5#%D0%97%D0%BE%D0%BB%D0%BE%D1%82%D0%BE. Причём один мессенджер переведёт русские символы в utf-8, другой — в cp1251, третий — в koi8-r.

Чтобы решить эти две проблемы в приложениях и был написан этот модуль.

=head1 SUBROUTINES/METHODS

=head2 bohemy

    $num = bohemy $unicode;

Возвращает числовую характеристику похожести текста на русский. 

Алгоритм основан на наблюдении, что в русском языке слово начинается на прописную или строчную букву, а затем состоит из строчных букв.

Таким образом, числовая характеристика, это сумма длин русско-похожих слов с разницей суммы длин русско-непохожих.

Принимает параметр:

=over 4

=item B<$unicode>

Текст в юникоде (с взведённым флажком utf8).

=back

=head2 decode

    $unicode = decode $octets, $encodings;
    ($unicode, $encoding) = decode $octets, $encodings;

Возвращает декодированный текст в скалярном контексте, а в списочном, ещё и определённую кодировку. 

Если ни одна из кодировок не подошла, то вместо юникода в первом параметре возвращаются октеты, а вместо кодировки - C<undef>:

	($octets, $encoding_is_undef) = decode $octets, [];

Принимает параметры:

=over 4

=item B<$unicode>

Текст в юникоде (с взведённым флажком utf8).

=item B<$encodings>

Cписок кодировок, которыми предлагается попробовать декодировать текст.

Необязательный. Значение по умолчанию: C<[qw/utf-8 cp1251 koi8-r/]>.

=back

=head2 detect

    $encoding = detect $octets, $encodings;

Возвращает определённую кодировку или C<undef>.

Параметры такие же как у L</"decode">.

=head2 file_find

	@files = file_find $path_to_directory;

Ищет файлы в директориях рекурсивно и возвращает список путей к ним.

Принимает параметр:

=over 4

=item B<$path_to_directory>

Путь к файлу или директории. Если путь не ведёт к директории, то он просто возвращается в списке.

=back

=head2 file_read

	$octets = file_read $path;

Считывает файл.

Возвращает текст в октетах.

Выбрасывает исключение, если открыть файл не удалось.

Принимает параметр:

=over 4

=item B<$path>

Путь к файлу.

=back

=head2 file_write

	file_write $path, $octets_or_unicode;

Перезаписывает файл строкой.

Ничего не возвращает.

Выбрасывает исключение, если открыть файл не удалось.

Принимает параметры:

=over 4

=item B<$path>

Путь к файлу.

=item B<$octets_or_unicode>

Новое тело файла в октетах или юникоде.

=back

=head2 file_decode

    $unicode = file_decode $path, $encodings;
    ($unicode, $encoding) = file_decode $path, $encodings;

Возвращает декодированный текст из файла в скалярном контексте, а в списочном, ещё и определённую кодировку. 

Если ни одна из кодировок не подошла, то вместо юникода в первом параметре возвращаются октеты, а вместо кодировки - C<undef>:

	($octets, $encoding_is_undef) = file_decode $path, [];

Принимает параметры:

=over 4

=item B<$path>

Путь к файлу.

=item B<$encodings>

Cписок кодировок, которыми предлагается попробовать декодировать текст.

Необязательный. Значение по умолчанию: C<[qw/utf-8 cp1251 koi8-r/]>.

=back

=head2 file_encode

    file_encode $path, $encoding, $unicode;

Переписывает текст в файле в указанной кодировке.

Принимает параметры:

=over 4

=item B<$path>

Путь к файлу.

=item B<$encoding>

Кодировка в которую следует перевести параметр C<unicode> перед записью в файл.

=item B<$unicode>

Новый текст файла в юникоде (с установленным флажком utf8).

=back

=head2 test_file

    $is_file = test_file $file, $exts, $interpreters;

Тестирует файл на соответствие указанным расширениям, а если расширения нет, то на соответсвие интерпретаторов к указанному в первой строке файла начинающейся на C<#!>.

Принимает параметры:

=over 4

=item B<$file>

Путь к файлу.

Обязательный.

=item B<$exts>

Список расширений для сопоставления, если он пуст, то подходит любое.

Необязательный. Значение по умолчанию: C<[]>.

=item B<$interpreters>

Список интерпретаторов для сопоставления, если он пуст, то подходит любой, главное, чтобы строка начиналась на C<#!>.

Необязательный. Значение по умолчанию: C<[]>.

=back

=head2 test_files

    @files = test_files $files, $exts, $interpreters;

Тестирует файлы на соответствие указанным расширениям или интерпретаторам.

Принимает параметры:

=over 4

=item B<$files>

Список файлов. 

Обязательный.

=item B<$exts>

Такой же как в B<test_file>.

=item B<$interpreters>

Такой же как в B<test_file>.

=back

=head2 change_files

    @files = change_files();

Возвращает изменённые файлы в репозитории git.

=head2 change_files

    @files = change_files_in_branch();

Возвращает изменённые файлы в ветке.

=head1 INSTALL

Установить можно любым менеджером C<perl> со B<CPAN>, например:

	$ sudo cpm install -g Octets::To::Unicode

=head1 DEPENDENCIES

Зависит от модулей:

=over 4

=item * Getopt::Long

=item * Encode

=item * List::Util

=item * Pod::Usage

=item * Term::ANSIColor

=back

и от B<perltidy> опционально:

=over 4

=item * Perl::Tidy

=back

=head1 RELEASE

Релиз на B<CPAN> осуществляется так:

=over 4

=item Обновить исходники:

	$ git pull
	
=item Отредактировать файл I<Changes>.

В файле I<Changes> нужно написать список изменений, которые вошли в этот релиз.

Изменения записываются в виде списка, одно изменение — один элемент списка. Элементы списка обозначаются символами тире `-`.

Список с изменениями нужно разместить между строкой `{{$NEXT}}` и строкой с предыдущим релизом.

Допустим, предыдущий релиз был 1.71. Тогда описание изменений нового релиза будет выглядеть так:

	{{$NEXT}}
	 
		- RU-5 Какой-то тикет, который вошел в релиз.
		- RU-6 Ещё один тикет, вошедший в релиз.
	 
	1.71 2021-05-07T08:52:18Z
	 
		- RU-4 Какой-то предыдущий тикет.

Обратите внимание — у нового релиза пока нет версии. Версия будет вычислена Миниллой при выполнении релиза и автоматически вписана в файл I<Changes> вместо метки C<{{$NEXT}}>.

=item Активировать локальную библиотеку:

	$ cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

Это нужно, чтобы не выполнять релиз под рутом.

=item Выполнить релиз:

	$ minil release
	
В процессе Минилла задаст несколько вопросов, в частности предложит выбрать номер новой версии.

Обычно на все вопросы нужно отвечать кнопкой "enter". Иначе лучше прервать процесс и внести изменения в конфигурационные файлы.

=back

=head1 LINKS

=over 4

=item * perltidy и cp1251 / L<https://habr.com/ru/post/664308/>.

=back

=head1 AUTHOR

Yaroslav O. Kosmina E<lt>darviarush@mail.ruE<gt>

=head1 LICENSE

⚖ B<GPLv3>

=cut
