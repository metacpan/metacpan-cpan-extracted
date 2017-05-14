Summary: Programma per l'esecuzione di esercizi
Name: Quizzer
Version: 0.08
Release: 1.1mlx
Copyright: GPL
Group: Applicazioni
Source: Quizzer-%{version}.tar.gz
BuildRoot: /var/tmp/Quizzer-root

%description
Quizzer permette di definire degli esercizi attraverso un semplice linguaggio
di configurazione. Il programma esegue gli esercizi e consente all'allievo
di rispondere. All fine viene mostrato il punteggio ottenuto.

Ringraziamenti a Joey Hess <joey@kitenet.net> per il sistema Debconf su cui
e' basato Quizzer.

%prep
%setup -q

%build

%install
make prefix=$RPM_BUILD_ROOT esercizi
make prefix=$RPM_BUILD_ROOT install-esercizi
make prefix=$RPM_BUILD_ROOT install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README INSTALL VERSION COPYING AUTHORS BUGS TODO
/usr/bin/Quizzer
/etc/Quizzer.conf
/etc/Quizzer.tpl
/usr/share/Quizzer/quiz-sample.txt
/usr/share/Quizzer/quiz-interactive.txt
/usr/share/Quizzer/quiz-long.txt
/usr/share/Quizzer/*.tar.gz
/usr/lib/perl5/*

%changelog

* Tue Mar 19 2002 ippo <ippo@madeinlinux.com>
- Aggiunta tutta la gestione di esercizi interattivi
- Modificate un bel po' di cosette
- Aggiunto il quiz di Giuliano

* Wed Feb 27 2002 ippo <ippo@madeinlinux.com>
- Aggiunto il modulo per la gestione dei checkboxes
- Modifiche per l'utilizzo del frontend Gtk

* Mon Feb 18 2002 ippo <ippo@madeinlinux.com>
- Creazione del pacchetto
