INCLUDEPATH += $$PWD

DEFINES += QT_UIC_PERL_GENERATOR

# Input
HEADERS += $$PWD/plextractimages.h \
           $$PWD/plwritedeclaration.h \
           $$PWD/plwriteicondata.h \
           $$PWD/plwriteicondeclaration.h \
           $$PWD/plwriteiconinitialization.h \
           $$PWD/plwriteinitialization.h

SOURCES += $$PWD/plextractimages.cpp \
           $$PWD/plwritedeclaration.cpp \
           $$PWD/plwriteicondata.cpp \
           $$PWD/plwriteicondeclaration.cpp \
           $$PWD/plwriteiconinitialization.cpp \
           $$PWD/plwriteinitialization.cpp
