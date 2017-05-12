#include <qdir.h>

struct QDir {
    enum FilterSpec {
	Dirs,
	Files,
	Drives,
	NoSymLinks,
	All,
	TypeMask,
	Readable,
	Writable,
	Executable,
	RWEMask,
	Modified,
	Hidden,
	System,
	AccessMask,
	DefaultFilter
    };
    enum SortSpec {
	Name,
	Time,
	Size,
	Unsorted,
	SortByMask,
	DirsFirst,
	Reversed,
	IgnoreCase,
	DefaultSort
    };
    QDir();
    QDir(const QDir &);
    QDir(const char *, const char * = 0, int = QDir::Name | QDir::IgnoreCase, int = QDir::All);
    ~QDir();
    QDir &operator = (const QDir &);
    QDir &operator = (const char *);
    bool operator == (const QDir &) const;
    bool operator != (const QDir &) const;
    QString absFilePath(const char *, bool = TRUE) const;
    QString absPath() const;
    const char *at(int) const : $this->operator [] ($1);
    QString canonicalPath() const;
    bool cd(const char *, bool = TRUE);
    bool cdUp();
    static QString cleanDirPath(const char *);
    static QString convertSeparators(const char *);
    void convertToAbs();
    uint count() const;
    static QDir current();
    static QString currentDirPath();
    QString dirName() const;
    static const QFileInfoList *drives();
    const QFileInfoList *entryInfoList(int = QDir::DefaultFilter, int = QDir::DefaultSort) const;
    const QFileInfoList *entryInfoList(const char *, int = QDir::DefaultFilter, int = QDir::DefaultSort) const;
    const QStrList *entryList(int = QDir::DefaultFilter, int = QDir::DefaultSort) const;
    const QStrList *entryList(const char *, int = QDir::DefaultFilter, int = QDir::DefaultSort) const;
    bool exists() const;
    bool exists(const char *, bool = TRUE);
    QString filePath(const char *, bool = TRUE) const;
    QDir::FilterSpec filter() const;
    static QDir home();
    static QString homeDirPath();
    bool isReadable() const;
    bool isRelative() const;
    static bool isRelativePath(const char *);
    bool isRoot() const;
    static bool match(const char *, const char *);
    bool matchAllDirs() const;
    bool mkdir(const char *, bool = TRUE) const;
    const char *nameFilter() const;
    const char *path() const;
    bool remove(const char *, bool = TRUE);
    bool rename(const char *, const char *, bool = TRUE);
    bool rmdir(const char *, bool = TRUE) const;
    static QDir root();
    static QString rootDirPath();
    static char separator();
    static bool setCurrent(const char *);
    void setFilter(int);
    void setMatchAllDirs(bool);
    void setNameFilter(const char *);
    void setPath(const char *);
    void setSorting(int);
    QDir::SortSpec sorting() const;
} Qt::Dir;
