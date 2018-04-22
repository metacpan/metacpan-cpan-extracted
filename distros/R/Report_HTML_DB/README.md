# report\_html\_db
Projeto de iniciação científica, componente utilizado para gerar site(com conteúdo dinâmico) baseado nos resultados de componentes utilizados anteriormente<br /><br /> 

Para instalar dependencias:<br /><br /> 

`sudo apt-get install sqlite3`<br /><br /> 

`cpan DBIx::Class Catalyst::Devel Catalyst::Runtime Catalyst::View::TT Catalyst::View::JSON Catalyst::Model::DBIC::Schema  DBIx::Class::Schema::Loader MooseX::NonMoose Helper::ResultSet::SetOperations LWP::UserAgent::Cached`<br /><br /> 

Para rodar:<br /><br /> 

`bigou_m.pl -c html_db.cnf -d database_name -u username_database -p password -h address -o output_dir`<br /><br /> 

Inicialize a aplicação de serviço:<br /><br />

`./output_dir/Organism-Service/script/organism_service_server.pl -r &`<br /><br /> 
Adicione o caminho do serviço na configuração do Organism-Website:<br /><br />
`echo "\nrest_endpoint http://127.0.0.1:3000\npipeline_id 4528" >> ./output_dir/Organism-Website/organism_website.conf`<br /><br /> 

`./output_dir/Organism-Website/script/organism_website_server.pl -r -p 8080 &`<br /><br /> 

  
Acesse o site:<br /><br /> 

http://127.0.0.1:8080<br /><br />                                                                                                                                     

You can see more informations in [Report_HTML_DB Wiki!](https://github.com/WendelHime/report_html_db/wiki)

