all : DiagramSceneResources.pm

DiagramSceneResources.pm : diagramscene.qrc images/*
	prcc4 diagramscene.qrc -o DiagramSceneResources.pm

clean :
	rm -f DiagramSceneResources.pm
