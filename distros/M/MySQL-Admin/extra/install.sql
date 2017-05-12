CREATE TABLE `actions` (
  `action` varchar(25) NOT NULL,
  `file` varchar(100) NOT NULL,
  `title` varchar(100) NOT NULL,
  `right` int(1) NOT NULL DEFAULT '0',
  `sub` varchar(25) NOT NULL DEFAULT 'main',
  `id` int(25) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `action_2` (`action`),
  KEY `action` (`action`)
) ENGINE=InnoDB AUTO_INCREMENT=124 DEFAULT CHARSET=utf8;
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('AddFulltext','tables.pl','AddFulltext','5','AddFulltext','1');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('AnalyzeTable','tables.pl','AnalyzeTable','5','AnalyzeTable','2');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('AddPrimaryKey','tables.pl','AddPrimaryKey','5','AddPrimaryKey','3');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ChangeEngine','tables.pl','ChangeEngine','5','ChangeEngine','4');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ChangeAutoInCrementValue','tables.pl','ChangeAutoInCrementValue','5','ChangeAutoInCrementValue','5');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ChangeCol','tables.pl','ChangeCol','5','ChangeCol','6');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ChangeCharset','tables.pl','ChangeCharset','5','ChangeCharset','7');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ChooseDataBase','tables.pl','ChooseDataBase','5','ChooseDataBase','8');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DropTable','tables.pl','DropTable','5','DropTable','9');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DeleteEntry','tables.pl','DeleteEntry','5','DeleteEntry','10');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DropCol','tables.pl','DropCol','5','DropCol','11');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowDumpTable','tables.pl','DumpTable','5','ShowDumpTable','12');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ExecSql','tables.pl','ExecSql','5','ExecSql','13');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('EditTable','tables.pl','SQL','5','EditTable','14');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('EditEntry','tables.pl','EditEntry','5','EditEntry','15');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('NewEntry','tables.pl','NewEntry','5','NewEntry','16');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('NewTable','tables.pl','NewTable','5','NewTable','17');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('CreateDatabase','tables.pl','CreateDatabase','5','CreateDatabase','18');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('OptimizeTable','tables.pl','OptimizeTable','5','OptimizeTable','19');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('RepairTable','tables.pl','RepairTable','5','RepairTable','20');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SaveEditTable','tables.pl','SaveEditTable','5','SaveEditTable','21');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SQL','tables.pl','SQL','5','SQL','22');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SaveEntry','tables.pl','SaveEntry','5','SaveEntry','23');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DropFulltext','tables.pl','DropFulltext','5','DropFulltext','24');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowTables','tables.pl','ShowTables','5','ShowTables','25');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowTableDetails','tables.pl','ShowTableDetails','5','ShowTableDetails','26');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowTable','tables.pl','ShowTable','5','ShowTable','27');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('TruncateTable','tables.pl','TruncateTable','5','TruncateTable','28');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowProcesslist','tables.pl','ShowProcesslist','5','ShowProcesslist','29');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('AddIndex','tables.pl','AddIndex','5','AddIndex','30');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DropIndex','tables.pl','DropFulltext','5','DropIndex','31');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('AddUnique','tables.pl','DropFulltext','5','AddUnique','32');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowNewEntry','tables.pl','ShowNewEntry','5','ShowNewEntry','33');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('MultipleAction','tables.pl','MultipleAction','5','MultipleAction','34');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowDumpDatabase','tables.pl','DumpDatabase','5','ShowDumpDatabase','35');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SaveNewTable','tables.pl','SaveNewTable','5','SaveNewTable','36');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('EditAction','tables.pl','EditAction','5','EditAction','37');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('MultipleDbAction','tables.pl','MultipleDbAction','5','MultipleDbAction','38');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('RenameTable','tables.pl','RenameTable','5','RenameTable','39');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SaveNewColumn','tables.pl','SaveNewColumn','5','SaveNewColumn','40');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('NewDatabase','tables.pl','NewDatabase','5','NewDatabase','41');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowEditIndex','tables.pl','ShowEditIndex','5','ShowEditIndex','42');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SaveNewIndex','tables.pl','SaveNewIndex','5','SaveNewIndex','43');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowRights','tables.pl','ShowRights','5','ShowRights','44');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('SaveRights','tables.pl','SaveRights','5','SaveRights','45');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowUsers','tables.pl','ShowUsers','5','ShowUsers','46');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('CreateUser','tables.pl','CreateUser','5','CreateUser','47');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DeleteUser','tables.pl','DeleteUser','5','DeleteUser','48');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('DropDatabase','tables.pl','DropDatabase','5','DropDatabase','49');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowDatabases','tables.pl','ShowDatabases','5','ShowDatabases','50');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowVariables','tables.pl','ShowVariables','5','ShowVariables','51');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('searchDatabase','tables.pl','searchDatabase','5','searchDatabase','52');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('showLogin','exploit.pl','','0','main','53');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('showProfile','tables.pl','showProfile','5','showProfile','54');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('saveProfile','tables.pl','Profile','5','saveProfile','55');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('searchHelpTopic','tables.pl','Help Topic','5','searchHelpTopic','56');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('login','login.pl','Login','0','main','57');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('quickbar','quickbar.pl','quickbar','5','main','58');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ShowNewTable','tables.pl','ShowNewTable','5','ShowNewTable','59');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('downLoadFile','tables.pl','downLoadFile','5','downLoadFile','60');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('news','news.pl','Blog','0','show','61');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('settings','quick.pl','Settings','5','main','62');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('addNews','news.pl','newMessage','0','addNews','63');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('admin','admin.pl','adminCenter','5','main','64');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('delete','news.pl','blog','0','deleteNews','65');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('edit','news.pl','blog','0','editNews','66');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('saveedit','news.pl','blog','0','saveedit','67');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('reply','news.pl','blog','0','replyNews','68');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('profile','profile.pl','Profile','1','main','69');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('reg','reg.pl','register','0','reg','70');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('addReply','news.pl','blog','0','addReply','71');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('showthread','news.pl','blog','0','showMessage','72');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('verify','reg.pl','verify','0','verify','73');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('fulltext','search.pl','search','0','fulltext','74');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('newTreeviewEntry','editTree.pl','newTreeViewEntry','5','newTreeviewEntry','75');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('saveTreeviewEntry','editTree.pl','saveTreeviewEntry','5','saveTreeviewEntry','76');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('editTreeview','editTree.pl','editTreeview','5','editTreeview','77');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('addTreeviewEntry','editTree.pl','addTreeviewEntry','5','addTreeviewEntry','78');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('editTreeviewEntry','editTree.pl','editTreeviewEntry','5','editTreeviewEntry','79');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('deleteTreeviewEntry','editTree.pl','deleteTreeviewEntry','5','deleteTreeviewEntry','80');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('upEntry','editTree.pl','upEntry','5','upEntry','81');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('downEntry','editTree.pl','downEntry','5','downEntry','82');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('links','links.pl','Bookmarks','0','ShowBookmarks','83');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('env','env.pl','env','5','main','84');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('lostpass','login.pl','lostpass','0','lostpass','85');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('getpass','login.pl','getpass','0','getpass','86');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('showDir','files.pl','Files','5','showDir','87');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('FileOpen','files.pl','FileOpen','5','FileOpen','88');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('newFile','files.pl','newFile','5','newFile','89');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('saveFile','files.pl','saveFile','5','saveFile','90');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('showMessage','news.pl','blog','0','main','91');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('chmodFile','files.pl','chmodFile','5','chmodFile','92');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('deleteFile','files.pl','deleteFile','5','deleteFile','93');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('makeDir','files.pl','Files','5','makeDir','94');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('newGbookEntry','gbook.pl','gbook','0','newGbookEntry','95');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('addnewGbookEntry','gbook.pl','gbook','0','addnewGbookEntry','96');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('gbook','gbook.pl','gbook','0','showGbook','97');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('deleteExploit','admin.pl','Admin','5','deleteExploit','98');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ImportOperaBookmarks','links.pl','ImportOperaBookmarks','5','ImportOperaBookmarks','99');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('linkseditTreeview','editTree.pl','linkseditTreeview','5','linkseditTreeview','100');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('EditFile','files.pl','EditAction','5','EditFile','101');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ExportOperaBookmarks','links.pl','ExportOperaBookmarks','0','ExportOperaBookmarks','102');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('MoveTreeViewEntry','editTree.pl','MoveTreeViewEntry','5','MoveTreeViewEntry','103');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('chownFile','files.pl','chownFile','5','chownFile','104');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('ImportFireFoxBookmarks','links.pl','ImportFireFoxBookmarks','5','ImportFireFoxBookmarks','105');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('rebuildtrash','news.pl','weblog','0','rebuildtrash','106');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('trash','news.pl','trash','5','trash','107');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('showaddTranslation','addtranslate.pl','showaddTranslation','5','main','108');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('translate','translate.pl','translate','5','main','109');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('deleteTreeviewEntrys','editTree.pl','Edit','5','deleteTreeviewEntrys','110');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('makeUser','reg.pl','register','0','make','111');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('navigation','navigation.pl','navigation','0','main','112');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('mainMenu','main.pl','Menu','0','main','113');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('impressum','impressum.pl','Impressum','0','main','114');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('HelpTopics','tables.pl','HelpTopics','5','HelpTopics','121');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('makePassword','reg.pl','makePassword','0','makePassword','122');
INSERT INTO `actions` (`action`,`file`,`title`,`right`,`sub`,`id`) values('lostPassword','reg.pl','lostPassword','0','lostPassword','123');

CREATE TABLE `actions_set` (
  `action` varchar(25) NOT NULL,
  `foreign_action` varchar(25) NOT NULL,
  `output_id` varchar(25) NOT NULL DEFAULT '25',
  `id` int(25) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `foreign_action` (`foreign_action`),
  CONSTRAINT `actions_set_ibfk_1` FOREIGN KEY (`foreign_action`) REFERENCES `actions` (`action`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=125 DEFAULT CHARSET=utf8;
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('AddFulltext','AddFulltext','content','1');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('AnalyzeTable','AnalyzeTable','content','2');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('AddPrimaryKey','AddPrimaryKey','content','3');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ChangeEngine','ChangeEngine','content','4');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ChangeAutoInCrementValue','ChangeAutoInCrementValue','content','5');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ChangeCol','ChangeCol','content','6');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ChangeCharset','ChangeCharset','content','7');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ChooseDataBase','ChooseDataBase','content','8');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DropTable','DropTable','content','9');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DeleteEntry','DeleteEntry','content','10');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DropCol','DropCol','content','11');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowDumpTable','ShowDumpTable','content','12');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ExecSql','ExecSql','content','13');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('EditTable','EditTable','content','14');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('EditEntry','EditEntry','content','15');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('NewEntry','NewEntry','content','16');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('NewTable','NewTable','content','17');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('CreateDatabase','CreateDatabase','content','18');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('OptimizeTable','OptimizeTable','content','19');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('RepairTable','RepairTable','content','20');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SaveEditTable','SaveEditTable','content','21');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SQL','SQL','content','22');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SaveEntry','SaveEntry','content','23');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DropFulltext','DropFulltext','content','24');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowTables','ShowTables','content','25');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowTableDetails','ShowTableDetails','content','26');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowTable','ShowTable','content','27');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('TruncateTable','TruncateTable','content','28');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowProcesslist','ShowProcesslist','content','29');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('AddIndex','AddIndex','content','30');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DropIndex','DropFulltext','content','31');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('AddUnique','AddUnique','content','32');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowNewEntry','ShowNewEntry','content','33');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('MultipleAction','MultipleAction','content','34');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowDumpDatabase','ShowDumpDatabase','content','35');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SaveNewTable','SaveNewTable','content','36');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('EditAction','EditAction','content','37');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('MultipleDbAction','MultipleDbAction','content','38');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('RenameTable','RenameTable','content','39');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SaveNewColumn','SaveNewColumn','content','40');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('NewDatabase','NewDatabase','content','41');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowEditIndex','ShowEditIndex','content','42');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SaveNewIndex','SaveNewIndex','content','43');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowRights','ShowRights','content','44');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('SaveRights','SaveRights','content','45');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowUsers','ShowUsers','content','46');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('CreateUser','CreateUser','content','47');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DeleteUser','DeleteUser','content','48');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('DropDatabase','DropDatabase','content','49');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowDatabases','ShowDatabases','content','50');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowVariables','ShowVariables','content','51');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('searchDatabase','searchDatabase','content','52');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showLogin','showLogin','content','53');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showProfile','showProfile','content','54');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('searchHelpTopic','searchHelpTopic','content','55');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowNewTable','ShowNewTable','content','56');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('downLoadFile','downLoadFile','content','57');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('news','news','content','58');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('settings','settings','content','59');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('addNews','addNews','content','60');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('admin','admin','content','61');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('delete','delete','content','62');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('edit','edit','content','63');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('saveedit','saveedit','content','64');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('reply','reply','content','65');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('profile','profile','content','66');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('reg','reg','content','67');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('addReply','addReply','content','68');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showthread','showthread','content','69');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('verify','verify','content','70');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('fulltext','fulltext','content','71');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('newTreeviewEntry','newTreeviewEntry','content','72');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('saveTreeviewEntry','saveTreeviewEntry','content','73');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('editTreeview','editTreeview','content','74');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('addTreeviewEntry','addTreeviewEntry','content','75');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('editTreeviewEntry','editTreeviewEntry','content','76');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('deleteTreeviewEntry','deleteTreeviewEntry','content','77');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('upEntry','upEntry','content','78');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('downEntry','downEntry','content','79');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('links','links','content','80');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('env','env','content','81');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('lostpass','lostpass','content','82');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('getpass','getpass','content','83');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showDir','showDir','content','84');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('FileOpen','FileOpen','content','85');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('newFile','newFile','content','86');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('saveFile','saveFile','content','87');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showMessage','showMessage','content','88');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('chmodFile','chmodFile','content','89');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('deleteFile','deleteFile','content','90');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('makeDir','makeDir','content','91');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('newGbookEntry','newGbookEntry','content','92');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('addnewGbookEntry','addnewGbookEntry','content','93');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('gbook','gbook','content','94');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('deleteExploit','deleteExploit','content','95');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ImportOperaBookmarks','ImportOperaBookmarks','\r\ncontent','96');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('linkseditTreeview','linkseditTreeview','content','97');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('EditFile','EditFile','content','98');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ExportOperaBookmarks','ExportOperaBookmarks','content','99');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('MoveTreeViewEntry','MoveTreeViewEntry','content','100');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('chownFile','chownFile','content','101');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ImportFireFoxBookmarks','ImportFireFoxBookmarks','content','102');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('rebuildtrash','rebuildtrash','content','103');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('trash','trash','content','104');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showaddTranslation','showaddTranslation','content','105');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('translate','translate','content','106');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('deleteTreeviewEntrys','deleteTreeviewEntrys','content','107');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('makeUser','makeUser','content','108');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('default','navigation','treeview','109');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('default','login','loginContent','110');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showDatabases','quickbar','quickbar','111');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('showLogin','login','content','112');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('mainMenu','mainMenu','menuBar','113');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('impressum','impressum','content','114');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('mute','mute','content','115');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('retweet','retweet','content','116');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('timeLine','timeLine','content','117');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('feeds','feeds','content','118');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('ShowTables','quickbar','quickbar','121');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('HelpTopics','HelpTopics','content','122');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('makePassword','makePassword','content','123');
INSERT INTO `actions_set` (`action`,`foreign_action`,`output_id`,`id`) values('lostPassword','lostPassword','content','124');

CREATE TABLE `cats` (
  `name` varchar(100) NOT NULL DEFAULT '',
  `right` int(11) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
INSERT INTO `cats` (`name`,`right`,`id`) values('news','0','6');
INSERT INTO `cats` (`name`,`right`,`id`) values('member','1','7');
INSERT INTO `cats` (`name`,`right`,`id`) values('draft','2','8');

CREATE TABLE `exploit` (
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `referer` text NOT NULL,
  `remote_addr` text NOT NULL,
  `query_string` text NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `count` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  FULLTEXT KEY `remote_addr` (`remote_addr`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `flood` (
  `remote_addr` text NOT NULL,
  `ti` text NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `gbook` (
  `title` varchar(50) NOT NULL DEFAULT '',
  `body` text NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user` text NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  FULLTEXT KEY `title` (`title`,`body`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `mainMenu` (
  `title` varchar(100) NOT NULL DEFAULT '',
  `action` varchar(100) NOT NULL DEFAULT '',
  `right` int(11) NOT NULL DEFAULT '0',
  `position` int(5) DEFAULT NULL,
  `menu` varchar(100) NOT NULL DEFAULT 'top',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `output` varchar(100) NOT NULL DEFAULT 'requestURI',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('blog','news','0','1','top','1','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('properties','profile','1','4','top','2','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('links','links','0','2','top','3','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('gbook','gbook','0','3','left','4','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('login','showLogin','0','5','left','5','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('fulltext','fulltext','0','6','left','6','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('admin','location.href=\'index.html\'','5','7','left','7','javascript');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('Impressum','impressum','0','8','top','8','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('EditFile','location.href =\'/index.html?/cgi-bin/mysql.pl?action=EditFile&name=\'+cAction','5','9','left','9','javascript');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('timeLine','timeLine','0','10','left','10','requestURI');
INSERT INTO `mainMenu` (`title`,`action`,`right`,`position`,`menu`,`id`,`output`) values('viewrss','feeds','0','11','left','11','requestURI');

CREATE TABLE `navigation` (
  `title` varchar(100) NOT NULL DEFAULT '',
  `action` varchar(100) NOT NULL DEFAULT '',
  `src` varchar(100) NOT NULL DEFAULT '',
  `right` int(11) NOT NULL DEFAULT '0',
  `position` int(5) DEFAULT NULL,
  `submenu` varchar(100) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `target` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
INSERT INTO `navigation` (`title`,`action`,`src`,`right`,`position`,`submenu`,`id`,`target`) values('blog','news','news.png','6','1','','1',NULL);
INSERT INTO `navigation` (`title`,`action`,`src`,`right`,`position`,`submenu`,`id`,`target`) values('Admin','admin','admin.png','5','3','submenuadmin','2',NULL);
INSERT INTO `navigation` (`title`,`action`,`src`,`right`,`position`,`submenu`,`id`,`target`) values('properties','profile','profile.png','1','5','','3',NULL);
INSERT INTO `navigation` (`title`,`action`,`src`,`right`,`position`,`submenu`,`id`,`target`) values('links','links','link.png','6','4','','4',NULL);
INSERT INTO `navigation` (`title`,`action`,`src`,`right`,`position`,`submenu`,`id`,`target`) values('gbook','gbook','link.png','6','8','','5',NULL);
INSERT INTO `navigation` (`title`,`action`,`src`,`right`,`position`,`submenu`,`id`,`target`) values('ShowDatabases','ShowDatabases','link.png','5','2','submenu_database','6',NULL);

CREATE TABLE `news` (
  `title` varchar(100) NOT NULL,
  `body` text NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user` text NOT NULL,
  `right` int(11) NOT NULL DEFAULT '0',
  `attach` varchar(100) NOT NULL DEFAULT '0',
  `cat` varchar(25) NOT NULL DEFAULT 'news',
  `action` varchar(50) NOT NULL DEFAULT 'main',
  `sticky` int(1) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `format` varchar(10) NOT NULL DEFAULT 'bbcode',
  PRIMARY KEY (`id`),
  FULLTEXT KEY `title` (`title`,`body`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
INSERT INTO `news` (`title`,`body`,`date`,`user`,`right`,`attach`,`cat`,`action`,`sticky`,`id`,`format`) values('Just a MySQL Administration Web-App.','<img src=\"images/logo.png\" alt=\"mysql-admin\" onclick=\"window.open(\'http://sourceforge.net/p/lindnerei\')\" style=\"cursor:pointer\">\r\n<br>\r\n<a target=\"_blank\" href=\"http://search.cpan.org/dist/MySQL-Admin/\">Cpan</a>|\r\n<a target=\"_blank\" href=\"http://metacpan.org/release/MySQL-Admin\">Metacpan</a>|\r\n<a target=\"_blank\" href=\"http://sourceforge.net/p/lindnerei\">Sourceforge</a>|\r\n<a target=\"_blank\" href=\"http://sourceforge.net/p/lindnerei/ajax/HEAD/tree/\">Svn</a>|\r\n<a target=\"_blank\" href=\"http://sourceforge.net/projects/lindnerei/files/latest/download\">Download</a>\r\n','2015-12-07 23:27:59','admin','0','0','news','news','0','1','html');

CREATE TABLE `querys` (
  `title` varchar(100) NOT NULL DEFAULT '',
  `description` text NOT NULL,
  `sql` text NOT NULL,
  `return` varchar(100) NOT NULL DEFAULT 'fetch_array',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `replies` (
  `title` varchar(100) NOT NULL,
  `body` text NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user` text NOT NULL,
  `right` int(10) NOT NULL DEFAULT '0',
  `attach` varchar(100) NOT NULL DEFAULT '0',
  `refererId` varchar(50) NOT NULL,
  `sticky` int(1) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `format` varchar(10) NOT NULL DEFAULT 'bbcode',
  `cat` varchar(25) NOT NULL DEFAULT 'replies',
  PRIMARY KEY (`id`),
  FULLTEXT KEY `title` (`title`,`body`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `submenu_database` (
  `title` varchar(100) NOT NULL DEFAULT '',
  `action` varchar(100) NOT NULL DEFAULT '',
  `src` varchar(100) NOT NULL DEFAULT 'link.gif',
  `right` int(11) NOT NULL DEFAULT '0',
  `submenu` varchar(100) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
INSERT INTO `submenu_database` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('ShowProcesslist','ShowProcesslist','','5','','1');
INSERT INTO `submenu_database` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('ShowVariables','ShowVariables','','5','','2');
INSERT INTO `submenu_database` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('ShowDumpDatabase','ShowDumpDatabase','','5','','3');
INSERT INTO `submenu_database` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('ShowTables','ShowTables','','5','','4');
INSERT INTO `submenu_database` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('ShowUsers','ShowUsers','','5','','5');
INSERT INTO `submenu_database` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('HelpTopics','HelpTopics','','5','','6');

CREATE TABLE `submenuadmin` (
  `title` varchar(100) NOT NULL DEFAULT '',
  `action` varchar(100) NOT NULL DEFAULT '',
  `src` varchar(100) NOT NULL DEFAULT 'link.gif',
  `right` int(11) NOT NULL DEFAULT '0',
  `submenu` varchar(100) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('settings','settings','link.gif','5','','1');
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('navigation','editTreeview','','5','','2');
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('env','env','link.gif','5','','3');
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('Editlinks','linkseditTreeview','link.gif','6','','4');
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('Explorer','showDir','link.gif','5','','5');
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('trash','trash','','5','','6');
INSERT INTO `submenuadmin` (`title`,`action`,`src`,`right`,`submenu`,`id`) values('translate','translate','link.png','5','','7');

CREATE TABLE `trash` (
  `table` varchar(50) NOT NULL DEFAULT '',
  `oldId` bigint(50) NOT NULL DEFAULT '0',
  `title` varchar(100) NOT NULL DEFAULT '',
  `body` text NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user` text NOT NULL,
  `right` int(11) NOT NULL DEFAULT '0',
  `attach` varchar(100) NOT NULL DEFAULT '0',
  `cat` varchar(25) NOT NULL DEFAULT 'main',
  `action` varchar(50) NOT NULL DEFAULT 'news',
  `sticky` int(1) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `format` varchar(10) NOT NULL DEFAULT 'bbcode',
  `refererId` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  FULLTEXT KEY `title` (`title`,`body`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `pass` text NOT NULL,
  `user` varchar(25) NOT NULL DEFAULT '',
  `date` date NOT NULL DEFAULT '2000-01-01',
  `email` varchar(100) NOT NULL DEFAULT '',
  `right` int(11) NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL DEFAULT '',
  `firstname` varchar(100) NOT NULL DEFAULT '',
  `street` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `postcode` varchar(20) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `sid` varchar(200) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `cats` text,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
INSERT INTO `users` (`pass`,`user`,`date`,`email`,`right`,`name`,`firstname`,`street`,`city`,`postcode`,`phone`,`sid`,`ip`,`cats`,`id`) values('guest','guest','2001-01-01','','0','','',NULL,NULL,NULL,NULL,'123','dd','news','1');
