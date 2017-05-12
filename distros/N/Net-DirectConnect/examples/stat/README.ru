Что это?
Бот для сбора статистики с нескольких DC хабов

Установка:

Установить модули:
cpan DBI Bundle::DBD::mysql DBD::SQLite
win: через ppm

Скачиваем свежее из svn:
svn co svn://svn.setun.net/dcppp/trunk/ dcppp
или и скачиваем более старый релиз 
http://search.cpan.org/dist/Net-DirectConnect/

идем в examples/stat

скопировать config.pl.dist в config.pl 
отредактировать config.pl
 например включить sqlite вместо mysql
 Можно переопределить любые настройки найденные в stat.cgi dcstat.conf stat.pl statlib.pm

Запустить например 
 perl stat.pl dc.hub.ru dc.hub.com:41111 1.2.3.4

Посмотреть статистику например
 perl stat.cgi > stat.html

Прикрутить например к апачу
 например как dcstat.conf
 или положить в htdocs
 не забыть прописать полный путь в конфиге для базы если sqlite

Использовать.



====
freebsd:
cd /usr/ports/devel/subversion && make install clean
cd /usr/local/www && svn co svn://svn.setun.net/dcppp/trunk/examples/stat dcstat
cd /usr/local/www/dcstat && svn co svn://svn.setun.net/dcppp/trunk/lib/Net

cd /usr/ports/databases/p5-DBD-mysql && make install clean
cd /usr/ports/www/apache22 && make install clean
cd /usr/local/www/dcstat
cp config.pl.dist config.pl
ee config.pl
ln -s dcstat.conf /usr/local/etc/apache22/Includes/
echo 'apache22_enable="YES"' >> /etc/rc.conf.local
/usr/local/etc/rc.d/apache22 restart
perl stat.pl dc.hub.ru otherhub.com:4111
http://localhost/dcstat
